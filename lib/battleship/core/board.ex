defmodule Battleship.Core.Board do
  defstruct [:grid]

  alias Battleship.Core.Ship

  defmodule Coordinate do
    defstruct [:row, :column, :occupied_by]

    @type t :: %__MODULE__{
            row: integer(),
            column: integer(),
            occupied_by: Ship.type_atom() | nil
          }
  end

  @type grid :: [Coordinate.t()]
  @type point :: {number(), number()}
  @type placement :: {point(), point()}

  @type t :: %__MODULE__{
          grid: grid()
        }

  @spec new() :: t()
  def new() do
    grid =
      for row <- Range.new(0, 9),
          col <- Range.new(0, 9) do
        %Coordinate{row: row, column: col, occupied_by: nil}
      end

    %__MODULE__{
      grid: grid
    }
  end

  @spec place(board :: t(), ship :: Ship.types(), placement :: placement()) ::
          {:ok, t()} | {:error, String.t(), t()}
  def place(%__MODULE__{grid: grid} = board, ship, placement) do
    cond do
      outside_bounds?(placement) ->
        {:error, "Ship placed outside board bounds", board}

      occupied?(grid, placement) ->
        {:error, "Ships can not overlap", board}

      true ->
        {:ok, %{board | grid: update_board_with_placement(grid, Ship.atom(ship), placement)}}
    end
  end

  @spec update_board_with_placement(
          grid :: grid(),
          ship_atom :: Ship.type_atom(),
          placement :: placement()
        ) :: grid()
  defp update_board_with_placement(grid, ship_atom, placement) do
    indexes_to_change = placement_indicies(placement)
    grid_with_indices = Enum.with_index(grid)

    grid_with_indices
    |> Enum.map(fn
      {coordinate, index} ->
        if Enum.member?(indexes_to_change, index) do
          %{coordinate | occupied_by: ship_atom}
        else
          coordinate
        end
    end)
  end

  @spec outside_bounds?(placement :: placement()) :: boolean()
  defp outside_bounds?({start, terminal}) do
    {start_row, start_column} = start
    {end_row, end_column} = terminal

    Enum.any?([start_row, start_column, end_row, end_column], fn number ->
      number < 0 || number > 9
    end)
  end

  @spec occupied?(grid :: grid(), placement :: placement()) :: boolean()
  defp occupied?(grid, placement) do
    placement_indicies(placement)
    |> Enum.map(&Enum.at(grid, &1))
    |> Enum.any?(&match?(%Coordinate{occupied_by: ship} when not is_nil(ship), &1))
  end

  @spec placement_indicies(placement :: placement()) :: [number()]
  defp placement_indicies({start, terminal}) do
    {start_row, start_column} = start
    {end_row, end_column} = terminal

    for row <- Range.new(start_row, end_row),
        col <- Range.new(start_column, end_column) do
      tens = 10 * col
      single = 1 * row
      tens + single
    end
  end
end
