defmodule Battleship.Core.GuessBoard do
  alias Battleship.Core.Board

  defmodule Coordinate do
    alias Battleship.Core.GuessBoard

    defstruct [:row, :column, :guess_result]

    @type guess_result :: :hit | :miss | :unknown

    @type t :: %__MODULE__{
            row: integer(),
            column: integer(),
            guess_result: guess_result()
          }

    def new(row, column) do
      %__MODULE__{row: row, column: column, guess_result: :unknown}
    end

    @spec designate_hit_result(coordinate :: t(), hit_result :: GuessBoard.hit_result()) :: t()
    def designate_hit_result(coordinate, hit_result) do
      case hit_result do
        :hit -> %{coordinate | guess_result: :hit}
        :miss -> %{coordinate | guess_result: :miss}
        _ -> coordinate
      end
    end
  end

  defstruct [:grid]

  @type hit_result :: :hit | :miss
  @type t :: %__MODULE__{grid: [Coordinate.t()]}

  def new() do
    grid =
      for row <- Range.new(0, 9),
          col <- Range.new(0, 9) do
        Coordinate.new(row, col)
      end

    %__MODULE__{grid: grid}
  end

  @spec handle_guess_result(
          guess_board :: t(),
          hit_result :: hit_result(),
          point :: Board.point()
        ) :: t()
  def handle_guess_result(%{grid: grid} = board, hit_result, point) do
    {start_row, start_column} = point
    index = start_row * 10 + start_column

    new_grid =
      Enum.with_index(grid)
      |> Enum.map(fn
        {coordinate, ^index} ->
          Coordinate.designate_hit_result(coordinate, hit_result)

        {coordinate, _} ->
          coordinate
      end)

    %{board | grid: new_grid}
  end
end
