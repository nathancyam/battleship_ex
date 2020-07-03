defmodule Battleship.Core.BoardTest do
  use ExUnit.Case

  alias Battleship.Core.{Board, Ship}

  describe "new/0" do
    test "creates a new grid when called" do
      board = Board.new()
      assert Enum.count(board.grid) == 100
    end
  end

  describe "place/3" do
    setup do
      %{board: Board.new()}
    end

    test "fails when the ship is placed outside the board", %{board: board} do
      submarine = Ship.new(:submarine)

      {:error, "Ship placed outside board bounds", new_board} =
        Board.place(board, submarine, {{0, 0}, {-3, 0}})

      assert new_board == board
    end

    test "fails when the ships overlap", %{board: board} do
      carrier = Ship.new(:carrier)
      destroyer = Ship.new(:destroyer)

      {:ok, new_board} = Board.place(board, carrier, {{0, 0}, {0, 5}})

      {:error, "Ships can not overlap", unchanged_board} =
        Board.place(new_board, destroyer, {{0, 2}, {2, 4}})

      assert unchanged_board == new_board
    end

    test "succeeds when the ship is placed", %{board: board} do
      carrier = Ship.new(:carrier)
      destroyer = Ship.new(:destroyer)

      {:ok, new_board} = Board.place(board, carrier, {{0, 0}, {0, 5}})
      {:ok, new_board} = Board.place(new_board, destroyer, {{2, 2}, {2, 5}})

      refute board == new_board
    end
  end
end
