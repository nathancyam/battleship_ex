defmodule Battleship.Server do
  use GenServer

  defmodule PlayerStatus do
    defstruct [:pid, :ready?]

    @type t :: %__MODULE__{
            pid: pid(),
            ready?: boolean()
          }

    @spec new(player_pid :: pid()) :: t()
    def new(player_pid) do
      %__MODULE__{
        pid: player_pid,
        ready?: false
      }
    end
  end

  defmodule State do
    defstruct [:player1, :player2, :by_pid]

    @type t :: %__MODULE__{
            player1: PlayerStatus.t() | nil,
            player2: PlayerStatus.t() | nil,
            by_pid: %{required(pid()) => PlayerStatus.t()}
          }

    def new() do
      %__MODULE__{
        player1: nil,
        player2: nil,
        by_pid: %{}
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

    def toggle_readiness(state, player_pid) do
      Map.from_struct(state)
      |> Enum.map(fn
        {k, %PlayerStatus{pid: ^player_pid} = v} ->
          {k, %{v | ready?: !v.ready?}}

        result ->
          result
      end)
      |> (&struct(State, &1)).()
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
  def register_player_socket(server, player_socket) do
    GenServer.call(server, {:add_player, player_socket})
  end

  def toggle_player_ready(server, player_socket) do
    GenServer.call(server, {:toggle_player_ready, player_socket})
  end

  def handle_call({:toggle_player_ready, player_socket}, _from, state) do
    new_state = State.toggle_readiness(state, player_socket)
    {:reply, {:ok, new_state}, new_state}
  end

  def handle_call({:add_player, player_socket}, _from, state) do
    case State.add_player(state, player_socket) do
      {:ok, state} = res ->
        {:reply, res, state}

      {:error, :game_full, state} = res ->
        {:reply, res, state}
    end
  end
end
