defmodule Battleship.Core.Notation do
  alias Battleship.Core.Board

  @doc ~s"""
  Converts the grid notation to a point tuple.

  A point tuple notates this:

  `{row, column}`

  In the case of rows and columns:

  - Columns are specified with alphabetical characters.
  - Rows are numbers.

  ## Examples

      iex> Battleship.Core.Notation.convert("A1")
      {0, 0}

      iex> Battleship.Core.Notation.convert("A2")
      {1, 0}

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

    row_axis =
      letter
      |> String.to_charlist()
      |> hd()

    col_axis =
      number
      |> String.to_integer()

    {col_axis - 1, row_axis - 65}
  end

  @spec point_to_index(point :: Board.point()) :: non_neg_integer()
  def point_to_index(point) do
    {row, column} = point
    row * 10 + column
  end
end
