defmodule Battleship.Core.PlayerTest do
  use ExUnit.Case
  alias Battleship.Core.{Board, Player, Ship}

  setup do
    %{player: Player.new("Example")}
  end

  describe "new/1" do
    test "creates a player instance with a new board", %{player: player} do
      assert player.name == "Example"
      refute player.board == nil
    end
  end

  describe "place/3" do
    test "errors when the placement is invalid", %{player: player} do
      carrier = Ship.new(:carrier)
      {:error, reason, updated_player} = Player.place(player, carrier, {{0, 0}, {0, 2}})
      assert reason == :invalid_placement
      assert player == updated_player
    end

    test "places the ships on the board and updates the board", %{player: player} do
      carrier = Ship.new(:carrier)
      {:ok, updated_player} = Player.place(player, carrier, {{0, 0}, {0, 4}})
      refute updated_player.board == player.board
    end
  end
end
