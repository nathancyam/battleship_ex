defmodule Battleship.Core.Notation do
  alias Battleship.Core.Board

  @doc ~s"""
  Converts the grid notation to a point tuple.

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

    y_axis =
      letter
      |> String.to_charlist()
      |> hd()

    x_axis =
      number
      |> String.to_integer()

    {x_axis - 1, y_axis - 65}
  end
end
