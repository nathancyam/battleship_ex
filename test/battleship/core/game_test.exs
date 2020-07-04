defmodule Battleship.Core.GameTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Battleship.Core.{ConsoleRenderer, Game, Notation, Player, PlayerNotReadyError, Ship}

  def create_ready_player(player_name) do
    steps = [
      {Ship.new(:carrier), {{0, 1}, {0, 5}}},
      {Ship.new(:battleship), {{5, 4}, {5, 1}}},
      {Ship.new(:destroyer), {{2, 2}, {2, 4}}},
      {Ship.new(:submarine), {{9, 4}, {8, 4}}},
      {Ship.new(:patrol_boat), {{4, 6}, {4, 7}}}
    ]

    Enum.reduce(steps, Player.new(player_name), fn {ship, placement}, player ->
      {:ok, player} = Player.place(player, ship, placement)
      player
    end)
  end

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
      perfect_game = [
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

      close_game = [
        {1, 0},
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

      turns = Enum.zip(perfect_game, close_game)

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
