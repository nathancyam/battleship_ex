defmodule Battleship.Core.ConsoleRendererTest do
  use ExUnit.Case

  import ExUnit.CaptureIO
  alias Battleship.Core.{Board, ConsoleRenderer, GuessBoard, Notation, Ship}

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
          {:ok, _tiles, updated_board} = Board.place(updated_board, ship, placement)
          updated_board
        end)

      board_io = capture_io(fn -> ConsoleRenderer.render(board) end)

      assert board_io =~
               """
               🌊🚢🚢🚢🚢🚢🌊🌊🌊🌊
               🌊🌊🌊🌊🌊🌊🌊🌊🌊🌊
               🌊🌊🚢🚢🚢🌊🌊🌊🌊🌊
               🌊🌊🌊🌊🌊🌊🌊🌊🌊🌊
               🌊🌊🌊🌊🌊🌊🚢🚢🌊🌊
               🌊🚢🚢🚢🚢🌊🌊🌊🌊🌊
               🌊🌊🌊🌊🌊🌊🌊🌊🌊🌊
               🌊🌊🌊🌊🌊🌊🌊🌊🌊🌊
               🌊🌊🌊🌊🚢🌊🌊🌊🌊🌊
               🌊🌊🌊🌊🚢🌊🌊🌊🌊🌊
               """
    end
  end

  describe "render/1 with GuessBoard" do
    setup do
      %{board: GuessBoard.new()}
    end

    test "renders an empty board", %{board: board} do
      board_io =
        capture_io(fn ->
          ConsoleRenderer.render(board)
        end)

      assert board_io == """
             ❓❓❓❓❓❓❓❓❓❓
             ❓❓❓❓❓❓❓❓❓❓
             ❓❓❓❓❓❓❓❓❓❓
             ❓❓❓❓❓❓❓❓❓❓
             ❓❓❓❓❓❓❓❓❓❓
             ❓❓❓❓❓❓❓❓❓❓
             ❓❓❓❓❓❓❓❓❓❓
             ❓❓❓❓❓❓❓❓❓❓
             ❓❓❓❓❓❓❓❓❓❓
             ❓❓❓❓❓❓❓❓❓❓
             """
    end

    test "renders a board with hits and misses", %{board: board} do
      new_board =
        board
        |> GuessBoard.handle_guess_result(:hit, {0, 0})
        |> GuessBoard.handle_guess_result(:hit, Notation.convert("A2"))
        |> GuessBoard.handle_guess_result(:hit, {0, 2})
        |> GuessBoard.handle_guess_result(:hit, {0, 3})
        |> GuessBoard.handle_guess_result(:miss, {2, 2})

      board_io =
        capture_io(fn ->
          ConsoleRenderer.render(new_board)
        end)

      assert board_io =~
               """
               💥❓💥💥❓❓❓❓❓❓
               💥❓❓❓❓❓❓❓❓❓
               ❓❓🌊❓❓❓❓❓❓❓
               ❓❓❓❓❓❓❓❓❓❓
               ❓❓❓❓❓❓❓❓❓❓
               ❓❓❓❓❓❓❓❓❓❓
               ❓❓❓❓❓❓❓❓❓❓
               ❓❓❓❓❓❓❓❓❓❓
               ❓❓❓❓❓❓❓❓❓❓
               ❓❓❓❓❓❓❓❓❓❓
               """
    end
  end
end
