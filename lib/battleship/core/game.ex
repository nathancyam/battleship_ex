defmodule Battleship.Core.Game do
  alias Battleship.Core.{Board, Player, PlayerNotReadyError}

  defstruct [:player1, :player2, :active_turn]

  @type turn :: :player1 | :player2

  @type t :: %__MODULE__{
          player1: Player.t(),
          player2: Player.t(),
          active_turn: turn()
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
      active_turn: :player1
    }
  end

  @spec guess(game :: t(), point :: Board.point()) :: {:miss | :hit, game :: t()}
  def guess(game, point) do
    target_player = target(game)

    case Player.confirm_hit(target_player, point) do
      {:hit, _} -> {:hit, swap_turn(game)}
      {:miss, _} -> {:miss, swap_turn(game)}
    end
  end

  @spec swap_turn(game :: t()) :: t()
  def swap_turn(%{active_turn: :player1} = game) do
    %{game | active_turn: :player2}
  end

  def swap_turn(%{active_turn: :player2} = game) do
    %{game | active_turn: :player1}
  end

  @spec target(game :: t()) :: Player.t()
  defp target(%{player1: player1, player2: player2, active_turn: turn}) do
    case turn do
      :player1 -> player2
      :player2 -> player1
    end
  end
end
