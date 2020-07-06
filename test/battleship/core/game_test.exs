defmodule Battleship.Core.GameTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Battleship.GameSetup
  alias Battleship.Core.{ConsoleRenderer, Game, Notation, Player, PlayerNotReadyError, Ship}

  describe "start!/2" do
    test "fails when player A is not ready" do
      playerA = Player.new("A")
      playerB = Player.new("B")

      assert_raise PlayerNotReadyError, fn ->
        Game.start!(playerA, playerB)
      end
    end

    test "fails when player B is not ready" do
      playerA = create_ready_player("A")
      playerB = Player.new("B")

      assert_raise PlayerNotReadyError, fn ->
        Game.start!(playerA, playerB)
      end
    end

    test "returns game when player boards are populated" do
      playerA = create_ready_player("A")
      playerB = create_ready_player("B")

      game = Game.start!(playerA, playerB)
      refute is_nil(game)
    end
  end

  describe "the game turns" do
    setup do
      playerA = create_ready_player("A")
      playerB = create_ready_player("B")

      %{game: Game.start!(playerA, playerB)}
    end

    test "should guess", %{game: game} do
      # Player A guesses A0
      {:continue, :miss, game} = Game.guess(game, Notation.convert("A1"))

      playerA_guess_board =
        capture_io(fn ->
          ConsoleRenderer.render(game.player1.guess_board)
        end)

      assert playerA_guess_board =~ """
             🌊❓❓❓❓❓❓❓❓❓
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

      playerB_board =
        capture_io(fn ->
          ConsoleRenderer.render(game.player2.board)
        end)

      assert playerB_board =~ """
             ❌🚢🚢🚢🚢🚢🌊🌊🌊🌊
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

      # Player B guesses A1
      {:continue, :hit, game} = Game.guess(game, Notation.convert("B1"))

      playerB_guess_board =
        capture_io(fn ->
          ConsoleRenderer.render(game.player2.guess_board)
        end)

      assert playerB_guess_board =~ """
             ❓💥❓❓❓❓❓❓❓❓
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

      playerA_board =
        capture_io(fn ->
          ConsoleRenderer.render(game.player1.board)
        end)

      assert playerA_board =~ """
             🌊💥🚢🚢🚢🚢🌊🌊🌊🌊
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

    test "full game", %{game: game} do
      turns = Enum.zip(perfect_selection(), close_selection())

      {_game, winner, _loser} =
        Enum.reduce_while(turns, game, fn {playerA, playerB}, acc ->
          {playerA_res, _, game} = winner = Game.guess(acc, playerA)
          {playerB_res, _, game} = loser = Game.guess(game, playerB)

          if playerA_res == :game_over || playerB_res == :game_over do
            {:halt, {game, winner, loser}}
          else
            {:cont, game}
          end
        end)

      {:game_over, winning_player, game} = winner
      assert winning_player.name == "A"
      assert game.over?

      playerA_board =
        capture_io(fn ->
          ConsoleRenderer.render(game.player1.board)
          ConsoleRenderer.render(game.player1.guess_board)
        end)

      assert playerA_board =~
               """
               🌊🚢💥💥💥💥🌊🌊🌊🌊
               ❌🌊🌊🌊🌊🌊🌊🌊🌊🌊
               🌊🌊💥💥💥🌊🌊🌊🌊🌊
               🌊🌊🌊🌊🌊🌊🌊🌊🌊🌊
               🌊🌊🌊🌊🌊🌊💥🚢🌊🌊
               🌊💥💥💥💥🌊🌊🌊🌊🌊
               🌊🌊🌊🌊🌊🌊🌊🌊🌊🌊
               🌊🌊🌊🌊🌊🌊🌊🌊🌊🌊
               🌊🌊🌊🌊💥🌊🌊🌊🌊🌊
               🌊🌊🌊🌊💥🌊🌊🌊🌊🌊
               """

      assert playerA_board =~
               """
               ❓💥💥💥💥💥❓❓❓❓
               ❓❓❓❓❓❓❓❓❓❓
               ❓❓💥💥💥❓❓❓❓❓
               ❓❓❓❓❓❓❓❓❓❓
               ❓❓❓❓❓❓💥💥❓❓
               ❓💥💥💥💥❓❓❓❓❓
               ❓❓❓❓❓❓❓❓❓❓
               ❓❓❓❓❓❓❓❓❓❓
               ❓❓❓❓💥❓❓❓❓❓
               ❓❓❓❓💥❓❓❓❓❓
               """

      playerB_board =
        capture_io(fn ->
          ConsoleRenderer.render(game.player2.board)
          ConsoleRenderer.render(game.player2.guess_board)
        end)

      assert playerB_board =~
               """
               🌊💥💥💥💥💥🌊🌊🌊🌊
               🌊🌊🌊🌊🌊🌊🌊🌊🌊🌊
               🌊🌊💥💥💥🌊🌊🌊🌊🌊
               🌊🌊🌊🌊🌊🌊🌊🌊🌊🌊
               🌊🌊🌊🌊🌊🌊💥💥🌊🌊
               🌊💥💥💥💥🌊🌊🌊🌊🌊
               🌊🌊🌊🌊🌊🌊🌊🌊🌊🌊
               🌊🌊🌊🌊🌊🌊🌊🌊🌊🌊
               🌊🌊🌊🌊💥🌊🌊🌊🌊🌊
               🌊🌊🌊🌊💥🌊🌊🌊🌊🌊
               """

      assert playerB_board =~
               """
               ❓❓💥💥💥💥❓❓❓❓
               🌊❓❓❓❓❓❓❓❓❓
               ❓❓💥💥💥❓❓❓❓❓
               ❓❓❓❓❓❓❓❓❓❓
               ❓❓❓❓❓❓💥❓❓❓
               ❓💥💥💥💥❓❓❓❓❓
               ❓❓❓❓❓❓❓❓❓❓
               ❓❓❓❓❓❓❓❓❓❓
               ❓❓❓❓💥❓❓❓❓❓
               ❓❓❓❓💥❓❓❓❓❓
               """
    end
  end
end
