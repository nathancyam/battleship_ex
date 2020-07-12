defmodule Battleship.Setup.State do
  require Logger

  alias Battleship.Core.{Player, Game}
  alias Battleship.Setup.PlayerStatus

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

  @spec no_players?(state :: t()) :: boolean()
  def no_players?(state) do
    state.player1 == nil and state.player2 == nil
  end

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
    |> (&struct(__MODULE__, &1)).()
  end

  @spec dispatch_player_joined(state :: t()) :: :ok
  def dispatch_player_joined(%{player1: player1, player2: player2}) do
    if player1 != nil and Process.alive?(player1.pid) do
      GenServer.cast(player1.pid, :player_joined)
    end

    if player2 != nil and Process.alive?(player2.pid) do
      GenServer.cast(player2.pid, :player_joined)
    end
  end

  @spec clear_player(state :: t(), player_pid :: pid()) :: t()
  def clear_player(state, player_pid) do
    state
    |> Map.from_struct()
    |> Enum.map(fn
      {k, %PlayerStatus{pid: ^player_pid}} ->
        Logger.info("leaving_player=#{inspect(player_pid)} setting left player to nil")
        {k, nil}

      {_k, %PlayerStatus{pid: remaining_player_pid}} = result ->
        Logger.info(
          "remaining_player=#{inspect(remaining_player_pid)} informing player that opponent left during setup"
        )

        GenServer.cast(remaining_player_pid, :player_left)
        result

      result ->
        result
    end)
    |> (&struct(__MODULE__, &1)).()
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
