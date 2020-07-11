defmodule Battleship.GameSetup do
  alias Battleship.Core.{Player, Ship}

  def create_ready_player(player_name) do
    steps = [
      {Ship.new(:carrier), {{0, 1}, {0, 5}}},
      {Ship.new(:battleship), {{5, 4}, {5, 1}}},
      {Ship.new(:destroyer), {{2, 2}, {2, 4}}},
      {Ship.new(:submarine), {{9, 4}, {8, 4}}},
      {Ship.new(:patrol_boat), {{4, 6}, {4, 7}}}
    ]

    Enum.reduce(steps, Player.new(player_name), fn {ship, placement}, player ->
      {:ok, _tiles, player} = Player.place(player, ship, placement)
      player
    end)
  end

  def perfect_selection() do
    [
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
  end

  def close_selection() do
    [
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
  end
end
