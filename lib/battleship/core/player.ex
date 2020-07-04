defmodule Battleship.Core.Player do
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

  @spec handle_hit_result(player :: t(), hit_result :: hit_result(), point :: Board.point()) ::
          t()
  def handle_hit_result(%{guess_board: board} = player, hit_result, point) do
    %{player | guess_board: GuessBoard.handle_guess_result(board, hit_result, point)}
  end

  @spec confirm_hit(player :: t(), point :: Board.point()) :: {hit_result(), t()}
  def confirm_hit(player, point) do
    if Board.ship_on_point?(player.board, point) do
      {:hit, player}
    else
      {:miss, player}
    end
  end
end
