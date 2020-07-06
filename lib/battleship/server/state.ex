defmodule Battleship.Server.State do
  require Logger

  alias Battleship.Core.{Player, Game}
  alias Battleship.Server.PlayerStatus

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
    |> (&struct(__MODULE__, &1)).()
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
