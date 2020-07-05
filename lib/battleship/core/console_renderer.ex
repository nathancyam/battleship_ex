defmodule Battleship.Core.ConsoleRenderer do
  alias Battleship.Core.{Board, GuessBoard}

  @spec render(board :: Board.t() | GuessBoard.t()) :: [any()]
  def render(%Board{grid: grid}) do
    walk_over(grid, &to_emoji/1)
  end

  def render(%GuessBoard{grid: grid}) do
    walk_over(grid, &to_emoji/1)
  end

  @spec walk_over(grid :: [any()], callback :: (any() -> String.t())) :: [any()]
  def walk_over(grid, callback) do
    Enum.chunk_every(grid, 10)
    |> Enum.map(fn tiles ->
      Enum.map(tiles, callback)
      |> IO.puts()
    end)
  end

  def to_emoji(coordinate) do
    case coordinate do
      %GuessBoard.Coordinate{guess_result: :hit} ->
        "💥"

      %GuessBoard.Coordinate{guess_result: :miss} ->
        "🌊"

      %GuessBoard.Coordinate{guess_result: :unknown} ->
        "❓"

      %Board.Coordinate{occupied_by: nil, hit?: false} ->
        "🌊"

      %Board.Coordinate{occupied_by: nil, hit?: true} ->
        "❌"

      %Board.Coordinate{occupied_by: _ship, hit?: true} ->
        "💥"

      %Board.Coordinate{occupied_by: _ship} ->
        "🚢"
    end
  end
end
