defmodule Battleship.Core.Game do
  alias Battleship.Core.{Board, Player, PlayerNotReadyError}

  defstruct [:player1, :player2, :active_turn, :over?]

  @type turn :: :player1 | :player2
  @type turn_result ::
          {:continue, :miss, t()}
          | {:continue, :hit, t()}
          | {:game_over, winner :: Player.t(), t()}

  @type t :: %__MODULE__{
          player1: Player.t(),
          player2: Player.t(),
          active_turn: turn(),
          over?: boolean()
        }

  @doc """
  Starts the game between 2 given players. Assumes that each player has
  populated their boards accordingly and starts the guessing phasing between
  the 2 players.
  """
  @spec start!(player1 :: Player.t(), player2 :: Player.t()) :: t()
  def start!(player1, player2) do
    unless Player.ready?(player1) do
      raise PlayerNotReadyError
    end

    unless Player.ready?(player2) do
      raise PlayerNotReadyError
    end

    %__MODULE__{
      player1: player1,
      player2: player2,
      active_turn: :player1,
      over?: false
    }
  end

  @spec change_active_turn(game :: t()) :: t()
  def change_active_turn(%{active_turn: :player1} = game), do: %{game | active_turn: :player2}

  def change_active_turn(%{active_turn: :player2} = game), do: %{game | active_turn: :player1}

  @doc """
  For a given game, guess the position of the ship. Whose turn it is is determined
  by an internal struct.
  """
  @spec guess(game :: t(), point :: Board.point()) :: turn_result()
  def guess(%__MODULE__{over?: true} = game, _point) do
    {_, current_player} = target(game)
    {:game_over, current_player, game}
  end

  def guess(game, point) do
    {target, current_player} = target(game)
    {hit_result, all_destroyed?, target} = Player.confirm_hit(target, point)
    current_player = Player.handle_hit_result(current_player, hit_result, point)

    if all_destroyed? do
      {:game_over, current_player, finish_game(game, current_player, target)}
    else
      {:continue, hit_result, swap_turn(game, current_player, target)}
    end
  end

  @spec swap_turn(game :: t(), current_player :: Player.t(), target :: Player.t()) :: t()
  defp swap_turn(%{active_turn: :player1} = game, current_player, target) do
    %{change_active_turn(game) | player1: current_player, player2: target}
  end

  defp swap_turn(%{active_turn: :player2} = game, current_player, target) do
    %{change_active_turn(game) | player2: current_player, player1: target}
  end

  @spec finish_game(game :: t(), winner :: Player.t(), loser :: Player.t()) :: t()
  defp finish_game(%{active_turn: :player1} = game, winner, loser) do
    %{game | player1: winner, player2: loser, over?: true, active_turn: :player1}
  end

  defp finish_game(%{active_turn: :player2} = game, winner, loser) do
    %{game | player2: winner, player1: loser, over?: true, active_turn: :player2}
  end

  @spec target(game :: t()) :: {Player.t(), Player.t()}
  defp target(%{player1: player1, player2: player2, active_turn: turn}) do
    case turn do
      :player1 -> {player2, player1}
      :player2 -> {player1, player2}
    end
  end
end
