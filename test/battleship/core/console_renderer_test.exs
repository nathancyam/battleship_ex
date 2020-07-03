defmodule Battleship.Core.ConsoleRendererTest do
  use ExUnit.Case

  import ExUnit.CaptureIO
  alias Battleship.Core.{Board, ConsoleRenderer, Ship}

  describe "render/1" do
    setup do
      %{board: Board.new()}
    end

    test "renders an empty board", %{board: board} do
      board_io =
        capture_io(fn ->
          ConsoleRenderer.render(board)
        end)

      assert board_io =~ """
             🌊🌊🌊🌊🌊🌊🌊🌊🌊🌊
             🌊🌊🌊🌊🌊🌊🌊🌊🌊🌊
             🌊🌊🌊🌊🌊🌊🌊🌊🌊🌊
             🌊🌊🌊🌊🌊🌊🌊🌊🌊🌊
             🌊🌊🌊🌊🌊🌊🌊🌊🌊🌊
             🌊🌊🌊🌊🌊🌊🌊🌊🌊🌊
             🌊🌊🌊🌊🌊🌊🌊🌊🌊🌊
             🌊🌊🌊🌊🌊🌊🌊🌊🌊🌊
             🌊🌊🌊🌊🌊🌊🌊🌊🌊🌊
             🌊🌊🌊🌊🌊🌊🌊🌊🌊🌊
             """
    end

    test "renders a board with ships", %{board: board} do
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

      board_io = capture_io(fn -> ConsoleRenderer.render(board) end)

      assert board_io =~ """
             🌊🌊🌊🌊🌊🌊🌊🌊🌊🌊
             🚢🌊🌊🌊🌊🚢🌊🌊🌊🌊
             🚢🌊🚢🌊🌊🚢🌊🌊🌊🌊
             🚢🌊🚢🌊🌊🚢🌊🌊🌊🌊
             🚢🌊🚢🌊🌊🚢🌊🌊🚢🚢
             🚢🌊🌊🌊🌊🌊🌊🌊🌊🌊
             🌊🌊🌊🌊🚢🌊🌊🌊🌊🌊
             🌊🌊🌊🌊🚢🌊🌊🌊🌊🌊
             🌊🌊🌊🌊🌊🌊🌊🌊🌊🌊
             🌊🌊🌊🌊🌊🌊🌊🌊🌊🌊
             """
    end
  end
end
