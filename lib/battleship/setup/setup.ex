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

  def init(_args), do: {:ok, State.new()}

  @spec register_player_socket(server :: pid(), player_socket :: pid()) ::
          register_result()
  def register_player_socket(server, player_socket),
    do: GenServer.call(server, {:add_player, player_socket})

  @spec start_game(server :: pid()) :: {game :: Game.t(), player1 :: pid(), player2 :: pid()}
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

  def handle_call(:start_game, _from, state) do
    %{game: game} = new_state = State.start_game(state)
    Logger.info("creating game and terminating game setup")
    {:stop, :normal, {game, new_state.player1.pid, new_state.player2.pid}, new_state}
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

  def handle_call({:toggle_player_ready, player_socket, player}, _from, state) do
    new_state = State.toggle_readiness(state, player_socket, player)
    {:reply, {:ok, new_state}, new_state}
  end

  def handle_continue(:player_joined, state) do
    State.dispatch_player_joined(state)
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
