defmodule Battleship.Core.ShipTest do
  use ExUnit.Case
  alias Battleship.Core.Ship

  describe "new/1" do
    test "throws argument error" do
      assert_raise ArgumentError, fn ->
        Ship.new(:invalid)
      end
    end
  end
end
