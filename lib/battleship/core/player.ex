defmodule Battleship.Core.Player do
  alias Battleship.Core.{Board, Ship}

  defstruct [:board, :name]

  @type t :: %__MODULE__{
          board: Board.t(),
          name: String.t()
        }

  @spec new(name :: String.t()) :: t()
  def new(name) do
    %__MODULE__{
      board: Board.new(),
      name: name
    }
  end

  @spec place(player :: t(), ship :: Ship.types(), placement :: Board.placement()) ::
          {:ok, t()} | {:error, String.t(), t()}
  def place(player, ship, placement) do
    case Board.place(player.board, ship, placement) do
      {:ok, board} ->
        {:ok, %{player | board: board}}

      {:error, reason, _board} ->
        {:error, reason, player}
    end
  end
end
