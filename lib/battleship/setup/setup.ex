defmodule Battleship.Setup do
  use GenServer, restart: :transient

  alias Battleship.Core.{Game, Player}
  alias Battleship.Setup.State

  require Logger

  @type register_result :: {:ok, State.t()} | {:error, :game_full, State.t()}

  def start_link(game_id) do
    name = {:via, Registry, {Battleship.GameRegistry, game_id}}
    GenServer.start_link(__MODULE__, {:ok, game_id}, name: name)
  end

  @spec init(any) :: {:ok, Battleship.Setup.State.t()}
  def init(_args), do: {:ok, State.new()}

  @spec register_player_socket(server :: pid(), player_socket :: pid()) ::
          register_result()
  def register_player_socket(server, player_socket),
    do: GenServer.call(server, {:add_player, player_socket})

  @spec start_game(server :: pid()) :: Keyword.t()
  def start_game(server) do
    GenServer.call(server, :start_game)
  end

  @spec toggle_player_ready(server :: pid(), player_socket :: pid(), player :: Player.t()) ::
          {:ok, new_state :: State.t(), pid()}
  def toggle_player_ready(server, player_socket, player) do
    Logger.info("server=#{inspect(server)} pid=#{inspect(self())} toggling player readiness")
    {:ok, new_state} = GenServer.call(server, {:toggle_player_ready, player_socket, player})
    {:ok, new_state, server}
  end

  @spec guess(server :: pid(), tile :: {non_neg_integer(), non_neg_integer()}) ::
          Game.turn_result()
  def guess(server, tile) do
    # TODO: Call process update the game state with placement
    #       Return the result of the selection back to the calling process
    GenServer.call(server, {:select_tile, tile})
  end

  def handle_call(:start_game, {from, _ref}, state) do
    %{game: game, player1: player1, player2: player2} = new_state = State.start_game(state)
    Logger.info("creating game and transitioning to game management")

    player1_assigns = [designation: :player1, game_in_session?: true, game_pid: self()]
    player2_assigns = [designation: :player2, game_in_session?: true, game_pid: self()]

    {game, return_assigns, dispatch_assigns} =
      case {player1.pid, player2.pid} do
        {^from, _} ->
          {game, player1_assigns, {player2.pid, player2_assigns}}

        {_, ^from} ->
          {Game.change_active_turn(game), player2_assigns, {player1.pid, player1_assigns}}
      end

    {:reply, return_assigns, %{new_state | game: game}, {:continue, {:second, dispatch_assigns}}}
  end

  def handle_call({:add_player, player_socket}, _from, state) do
    Process.monitor(player_socket)

    case State.add_player(state, player_socket) do
      {:ok, new_state} = res ->
        if state.player2 == nil and new_state.player2 != nil do
          {:reply, res, new_state, {:continue, :player_joined}}
        else
          {:reply, res, new_state}
        end

      {:error, :game_full, state} = res ->
        {:reply, res, state}
    end
  end

  def handle_call({:select_tile, tile}, from, state) do
    {guess_result, new_state} = State.guess(state, tile)
    {:reply, guess_result, new_state, {:continue, {:notify_opponent, tile, from}}}
  end

  def handle_call({:toggle_player_ready, player_socket, player}, _from, state) do
    new_state = State.toggle_readiness(state, player_socket, player)
    {:reply, {:ok, new_state}, new_state}
  end

  def handle_continue({:second, {player_pid, assigns}}, state) do
    GenServer.cast(player_pid, {:update_assigns, Keyword.put(assigns, :turn_lock?, true)})
    {:noreply, state}
  end

  def handle_continue(:player_joined, state) do
    State.dispatch_player_joined(state)
    {:noreply, state}
  end

  def handle_continue({:notify_opponent, tile, player_pid}, state) do
    case Map.get(state, state.game.active_turn) do
      %{pid: opponent_pid} when is_pid(opponent_pid) ->
        tiles =
          state.game
          |> Map.get(state.game.active_turn)
          |> Player.tiles_at_boards(tile)

        GenServer.cast(opponent_pid, {:receive_selection_from_opponent, tile, tiles})

      nil ->
        Logger.warn("opponent pid could not be found.")
    end

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, down_player, _reason}, state) do
    new_state = State.clear_player(state, down_player)

    if State.no_players?(new_state) do
      {:stop, :normal, new_state}
    else
      {:noreply, new_state}
    end
  end
end
