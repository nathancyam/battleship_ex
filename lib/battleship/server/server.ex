defmodule Battleship.Server do
  use GenServer
  alias Battleship.Core.{Game, Player}

  require Logger

  defmodule PlayerStatus do
    defstruct [:pid, :ready?, :player]

    @type t :: %__MODULE__{
            pid: pid(),
            ready?: boolean(),
            player: Player.t() | nil
          }

    @spec new(player_pid :: pid()) :: t()
    def new(player_pid) do
      %__MODULE__{
        pid: player_pid,
        ready?: false,
        player: nil
      }
    end
  end

  defmodule State do
    defstruct [:player1, :player2, :game]

    @type t :: %__MODULE__{
            player1: PlayerStatus.t() | nil,
            player2: PlayerStatus.t() | nil,
            game: Game.t() | nil
          }

    def new() do
      %__MODULE__{
        player1: nil,
        player2: nil,
        game: nil
      }
    end

    @spec add_player(state :: t(), player_pid :: pid()) :: {:ok, t()} | {:error, :game_full, t()}
    def add_player(%__MODULE__{player1: nil, player2: nil} = state, player_pid) do
      status = PlayerStatus.new(player_pid)
      {:ok, %{state | player1: status}}
    end

    def add_player(
          %__MODULE__{player1: player1, player2: nil} = state,
          player_pid
        )
        when not is_nil(player1) do
      status = PlayerStatus.new(player_pid)
      {:ok, %{state | player2: status}}
    end

    def add_player(%__MODULE__{} = state, _pid), do: {:error, :game_full, state}

    @spec toggle_readiness(state :: t(), player_pid :: pid(), player :: Player.t()) :: t()
    def toggle_readiness(state, player_pid, player) do
      state
      |> Map.from_struct()
      |> Enum.map(fn
        {k, %PlayerStatus{pid: ^player_pid} = v} ->
          {k, %{v | ready?: !v.ready?, player: player}}

        result ->
          result
      end)
      |> (&struct(State, &1)).()
    end

    @spec clear_player(state :: t(), player_pid :: pid()) :: t()
    def clear_player(state, player_pid) do
      state
      |> Map.from_struct()
      |> Enum.map(fn
        {k, %PlayerStatus{pid: ^player_pid}} ->
          {k, nil}

        result ->
          result
      end)
      |> (&struct(State, &1)).()
    end

    @spec game_ready?(state :: t()) :: boolean()
    def game_ready?(%{player1: %{ready?: player1_ready?}, player2: %{ready?: player2_ready?}}) do
      player1_ready? and player2_ready?
    end

    def game_ready?(_), do: false

    @spec start_game(state :: t()) :: t()
    def start_game(%{player1: player1, player2: player2} = state) do
      Logger.info("starting game")
      %{state | game: Game.start!(player1.player, player2.player)}
    end
  end

  @type register_result :: {:ok, State.t()} | {:error, :game_full, State.t()}

  def start_link(game_id) do
    name = {:via, Registry, {Battleship.GameRegistry, game_id}}
    GenServer.start_link(__MODULE__, {:ok, game_id}, name: name)
  end

  def init(_args) do
    {:ok, State.new()}
  end

  @spec register_player_socket(server :: pid(), player_socket :: pid()) ::
          register_result()
  def register_player_socket(server, player_socket),
    do: GenServer.call(server, {:add_player, player_socket})

  def start_game(server) do
    GenServer.call(server, :start_game)
  end

  @spec toggle_player_ready(server :: pid(), player_socket :: pid(), player :: Player.t()) ::
          {:ok, State.t()}
  def toggle_player_ready(server, player_socket, player) do
    Logger.info("server=#{inspect(server)} pid=#{inspect(self())} toggling player readiness")
    {:ok, new_state} = GenServer.call(server, {:toggle_player_ready, player_socket, player})

    if State.game_ready?(new_state) do
      start_game(server)
    else
      {:ok, new_state}
    end
  end

  def handle_call(:start_game, _from, state) do
    %{game: game} = new_state = State.start_game(state)
    Logger.info("calling player 1 PID")

    Task.start(fn ->
      # Fugly hack to get around nested gen_server casts
      Process.sleep(1000)

      GenServer.call(
        state.player1.pid,
        {:start_game, game, {state.player1.pid, state.player2.pid}}
      )
    end)

    {:reply, {:ok, new_state}, new_state}
  end

  def handle_call({:add_player, player_socket}, _from, state) do
    Process.monitor(player_socket)

    case State.add_player(state, player_socket) do
      {:ok, state} = res ->
        {:reply, res, state}

      {:error, :game_full, state} = res ->
        {:reply, res, state}
    end
  end

  def handle_call({:toggle_player_ready, player_socket, player}, _from, state) do
    new_state = State.toggle_readiness(state, player_socket, player)
    {:reply, {:ok, new_state}, new_state}
  end

  def handle_info({:DOWN, _ref, :process, down_player, _reason}, state) do
    new_state = State.clear_player(state, down_player)
    {:noreply, new_state}
  end
end
