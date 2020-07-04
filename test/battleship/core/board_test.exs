defmodule Battleship.Core.BoardTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

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

      {:error, :out_of_bounds, new_board} = Board.place(board, submarine, {{0, 0}, {-1, 0}})

      assert new_board == board
    end

    test "fails when the ships overlap", %{board: board} do
      carrier = Ship.new(:carrier)
      destroyer = Ship.new(:destroyer)

      {:ok, new_board} = Board.place(board, carrier, {{0, 0}, {0, 4}})

      {:error, :overlap, unchanged_board} = Board.place(new_board, destroyer, {{0, 2}, {2, 2}})

      assert unchanged_board == new_board
    end

    test "fails when the ships and the placement coordinates are invalid", %{board: board} do
      submarine = Ship.new(:submarine)

      {:error, :invalid_placement, new_board} = Board.place(board, submarine, {{0, 0}, {3, 0}})

      assert new_board == board
    end

    test "fails when the board is full", %{board: board} do
      steps = [
        {Ship.new(:carrier), {{0, 1}, {0, 5}}},
        {Ship.new(:battleship), {{5, 4}, {5, 1}}},
        {Ship.new(:destroyer), {{2, 2}, {2, 4}}},
        {Ship.new(:submarine), {{9, 4}, {8, 4}}},
        {Ship.new(:patrol_boat), {{4, 6}, {4, 7}}}
      ]

      board =
        Enum.reduce(steps, board, fn {ship, placement}, updated_board ->
          {:ok, updated_board} = Board.place(updated_board, ship, placement)
          updated_board
        end)

      {:error, error, _board} = Board.place(board, Ship.new(:submarine), {{9, 4}, {8, 4}})
      assert board.ready?
      assert error == :board_full
    end

    test "succeeds when the ship is placed", %{board: board} do
      carrier = Ship.new(:carrier)
      destroyer = Ship.new(:destroyer)

      {:ok, new_board} = Board.place(board, carrier, {{0, 0}, {0, 4}})
      {:ok, new_board} = Board.place(new_board, destroyer, {{2, 2}, {2, 4}})

      refute board == new_board

      assert new_board.positions == %{
               %Ship{type: :carrier} => [0, 1, 2, 3, 4],
               %Ship{type: :destroyer} => [22, 23, 24]
             }
    end
  end

  describe "all_destroyed?/1" do
    setup do
      steps = [
        {Ship.new(:carrier), {{0, 1}, {0, 5}}},
        {Ship.new(:battleship), {{5, 4}, {5, 1}}},
        {Ship.new(:destroyer), {{2, 2}, {2, 4}}},
        {Ship.new(:submarine), {{9, 4}, {8, 4}}},
        {Ship.new(:patrol_boat), {{4, 6}, {4, 7}}}
      ]

      board =
        Enum.reduce(steps, Board.new(), fn {ship, placement}, updated_board ->
          {:ok, updated_board} = Board.place(updated_board, ship, placement)
          updated_board
        end)

      %{board: board}
    end

    test "returns true when all ships are destroyed", %{board: board} do
      points = [
        {0, 1},
        {0, 2},
        {0, 3},
        {0, 4},
        {0, 5},
        {5, 4},
        {5, 3},
        {5, 2},
        {5, 1},
        {2, 2},
        {2, 3},
        {2, 4},
        {9, 4},
        {8, 4},
        {4, 6},
        {4, 7}
      ]

      board =
        for point <- points, reduce: board do
          acc ->
            {_, new_board} = Board.handle_point_selection(acc, point)
            new_board
        end

      board_io =
        capture_io(fn ->
          Battleship.Core.ConsoleRenderer.render(board)
        end)

      refute board_io =~ "🚢"
      assert Board.all_destroyed?(board)
    end
  end
end
