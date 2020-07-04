defmodule Battleship.Core.Board do
  defstruct [:grid, :positions, :ready?]

  alias Battleship.Core.Ship

  defmodule Coordinate do
    defstruct [:row, :column, :occupied_by]

    @type t :: %__MODULE__{
            row: integer(),
            column: integer(),
            occupied_by: Ship.type_atom() | nil
          }

    def new(row, column) do
      %__MODULE__{row: row, column: column, occupied_by: nil}
    end
  end

  @typep axis :: 0..9
  @type point :: {axis(), axis()}
  @type placement :: {point(), point()}
  @type error :: :out_of_bounds | :overlap | :invalid_placement | :board_full

  @type grid :: [Coordinate.t()]
  @type t :: %__MODULE__{
          grid: grid(),
          positions: %{optional(Ship.types()) => [integer()]}
        }

  @spec new() :: t()
  def new() do
    grid =
      for row <- Range.new(0, 9),
          col <- Range.new(0, 9) do
        Coordinate.new(row, col)
      end

    %__MODULE__{
      grid: grid,
      ready?: false,
      positions: %{}
    }
  end

  @doc """
  Places a ship piece to the board given the placement notation as the third
  argument. If the placement is invalid, returns a tuple with the error and the
  board before the placement. If the placement was valid, return the tuple with
  the updated board.
  """
  @spec place(board :: t(), ship :: Ship.types(), placement :: placement()) ::
          {:ok, t()} | {:error, error(), t()}
  def place(%__MODULE__{grid: grid, positions: positions} = board, ship, placement) do
    cond do
      Enum.count(positions) == 5 ->
        {:error, :board_full, board}

      invalid_placement_for_ship?(placement, ship) ->
        {:error, :invalid_placement, board}

      outside_bounds?(placement) ->
        {:error, :out_of_bounds, board}

      occupied?(grid, placement) ->
        {:error, :overlap, board}

      true ->
        {indices, new_grid} = update_board_with_placement(grid, Ship.atom(ship), placement)
        updated_ship_positions = Map.put(positions, ship, indices)
        ready? = Enum.count(updated_ship_positions)
        {:ok, %{board | grid: new_grid, positions: updated_ship_positions, ready?: ready?}}
    end
  end

  @spec ship_on_point?(board :: t(), point :: point()) :: boolean()
  def ship_on_point?(board, point) do
    {start_row, start_column} = point
    index = start_row * 10 + start_column

    Enum.reduce_while(board.positions, false, fn {_ship, placement}, acc ->
      if Enum.member?(placement, index) do
        {:halt, true}
      else
        {:cont, acc}
      end
    end)
  end

  @spec update_board_with_placement(
          grid :: grid(),
          ship_atom :: Ship.type_atom(),
          placement :: placement()
        ) :: {indices :: [non_neg_integer()], grid :: grid()}
  defp update_board_with_placement(grid, ship_atom, placement) do
    indexes_to_change = placement_indicies(placement)
    grid_with_indices = Enum.with_index(grid)

    updated_grid =
      grid_with_indices
      |> Enum.map(fn
        {coordinate, index} ->
          if Enum.member?(indexes_to_change, index) do
            %{coordinate | occupied_by: ship_atom}
          else
            coordinate
          end
      end)

    {indexes_to_change, updated_grid}
  end

  @spec invalid_placement_for_ship?(placement :: placement(), ship :: Ship.types()) :: boolean()
  defp invalid_placement_for_ship?(placement, ship) do
    case rotation_with_distance(placement) do
      :diagonal ->
        true

      {_axis, distance} ->
        Ship.length(ship) != distance + 1
    end
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

  @spec rotation_with_distance(placement :: placement()) ::
          :diagonal | {axis :: :x_axis | :y_axis, distance :: pos_integer()}
  defp rotation_with_distance({start, terminal}) do
    {start_row, start_column} = start
    {end_row, end_column} = terminal

    cond do
      start_row != end_row and start_column != end_column ->
        :diagonal

      start_row == end_row ->
        {:x_axis, abs(start_column - end_column)}

      start_column == end_column ->
        {:y_axis, abs(start_row - end_row)}
    end
  end

  @spec placement_indicies(placement :: placement()) :: [non_neg_integer()]
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
