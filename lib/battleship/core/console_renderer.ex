defmodule Battleship.Core.ConsoleRenderer do
  alias Battleship.Core.Board

  @spec render(board :: Board.t()) :: [any()]
  def render(%Board{grid: grid}) do
    Enum.chunk_every(grid, 10)
    |> Enum.map(fn cordinates ->
      Enum.map(cordinates, fn
        %Board.Coordinate{occupied_by: nil} ->
          "🌊"

        %Board.Coordinate{occupied_by: _ship} ->
          "🚢"
      end)
      |> IO.puts()
    end)
  end
end
