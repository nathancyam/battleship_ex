defmodule Battleship.Core.GameTest do
  use ExUnit.Case
  alias Battleship.Core.{Game, Notation, Player, PlayerNotReadyError, Ship}

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
    test "fails when players are not ready" do
      playerA = Player.new("A")
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

  describe "the game process" do
    setup do
      playerA = create_ready_player("A")
      playerB = create_ready_player("B")

      %{game: Game.start!(playerA, playerB)}
    end

    @tag debug: true
    test "should guess", %{game: game} do
      # Player A guesses A0
      {:miss, game} = Game.guess(game, Notation.convert("A1"))
      # Player B guesses A1
      {:hit, _game} = Game.guess(game, Notation.convert("A2"))
    end
  end
end
