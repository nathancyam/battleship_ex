defmodule Battleship.Core.Notation do
  alias Battleship.Core.Board

  @doc ~s"""
  Converts the grid notation to a point tuple.

  ## Examples

      iex> Battleship.Core.Notation.convert("A1")
      {0, 0}

      iex> Battleship.Core.Notation.convert("A2")
      {0, 1}

      iex> Battleship.Core.Notation.convert("D4")
      {3, 3}

      iex> Battleship.Core.Notation.convert("c3")
      {2, 2}
  """
  @spec convert(notation :: String.t()) :: Board.point()
  def convert(notation) do
    upcased =
      notation
      |> String.trim()
      |> String.upcase()

    [letter, number] = String.split(upcased, "", trim: true)

    x_axis =
      letter
      |> String.to_charlist()
      |> hd()

    y_axis =
      number
      |> String.to_integer()

    {x_axis - 65, y_axis - 1}
  end

  @spec point_to_index(point :: Board.point()) :: non_neg_integer()
  def point_to_index(point) do
    {row, column} = point
    column * 10 + row
  end
end
