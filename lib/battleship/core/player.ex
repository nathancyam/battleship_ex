defmodule Battleship.Core.Player do
  @moduledoc """
  A player module that contains all the player operations.
  """

  alias Battleship.Core.{Board, GuessBoard, Ship}

  defstruct [:board, :name, :guess_board]

  @type hit_result :: :miss | :hit
  @type t :: %__MODULE__{
          board: Board.t(),
          name: String.t(),
          guess_board: GuessBoard.t()
        }

  @spec new(name :: String.t()) :: t()
  def new(name) do
    %__MODULE__{
      board: Board.new(),
      guess_board: GuessBoard.new(),
      name: name
    }
  end

  @spec ready?(player :: t()) :: boolean()
  def ready?(player), do: player.board.ready?

  @spec place(player :: t(), ship :: Ship.types(), placement :: Board.placement()) ::
          {:ok, t()} | {:error, Board.error(), t()}
  def place(player, ship, placement) do
    case Board.place(player.board, ship, placement) do
      {:ok, board} ->
        {:ok, %{player | board: board}}

      {:error, reason, _board} ->
        {:error, reason, player}
    end
  end

  @doc """
  Updates the player's guess board to notate the result of their guess.
  """
  @spec handle_hit_result(player :: t(), hit_result :: hit_result(), point :: Board.point()) ::
          t()
  def handle_hit_result(%{guess_board: board} = player, hit_result, point) do
    %{player | guess_board: GuessBoard.handle_guess_result(board, hit_result, point)}
  end

  @doc """
  Confirms whether the tile selection was a hit.

  TODO: Should update the player's board to say that a hit was made.
  """
  @spec confirm_hit(player :: t(), point :: Board.point()) :: {hit_result(), t()}
  def confirm_hit(player, point) do
    {hit_result, board} = Board.handle_point_selection(player.board, point)
    {hit_result, %{player | board: board}}
  end
end
