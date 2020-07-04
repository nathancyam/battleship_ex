defmodule Battleship.Core.GuessBoardTest do
  use ExUnit.Case
  alias Battleship.Core.GuessBoard

  describe "new/0" do
    test "creates a new guess board" do
      board = GuessBoard.new()
      assert board.__struct__ == GuessBoard
    end
  end

  describe "handle_guess_result/3" do
    setup do
      %{board: GuessBoard.new()}
    end

    test "updates the coordinate to hit", %{board: board} do
      new_guess_board = GuessBoard.handle_guess_result(board, :hit, {0, 0})

      old_tile = Enum.at(board.grid, 0)
      new_tile = Enum.at(new_guess_board.grid, 0)

      assert old_tile.guess_result == :unknown
      assert new_tile.guess_result == :hit
    end

    test "updates the coordinate to miss", %{board: board} do
      new_guess_board = GuessBoard.handle_guess_result(board, :miss, {0, 0})

      old_tile = Enum.at(board.grid, 0)
      new_tile = Enum.at(new_guess_board.grid, 0)

      assert old_tile.guess_result == :unknown
      assert new_tile.guess_result == :miss
    end
  end
end
