defmodule Battleship.Core.Player do
  alias Battleship.Core.{Board, Ship}

  defstruct [:board, :name]

  @type hit_result :: :miss | :hit
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

  @spec ready?(player :: t()) :: boolean()
  def ready?(player), do: player.board.ready?

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

  @spec confirm_hit(player :: t(), point :: Board.point()) :: {hit_result(), t()}
  def confirm_hit(player, point) do
    if Board.ship_on_point?(player.board, point) do
      {:hit, player}
    else
      {:miss, player}
    end
  end
end
