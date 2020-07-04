defmodule Battleship.Server.ServerTest do
  use ExUnit.Case
  alias Battleship.Server

  describe "start_link/1" do
    test "starts the process with the registry" do
      {:ok, pid} = Server.start_link("game_id")
      assert Process.alive?(pid)

      registry_res = Registry.lookup(Battleship.GameRegistry, "game_id")
      assert registry_res == [{pid, nil}]
    end
  end

  describe "supervisor" do
    test "restarts the process when killed" do
      {:ok, pid} = Battleship.GameSupervisor.start_game("game_id")

      Process.exit(pid, :kill)
      Process.sleep(50)

      [{new_pid, nil}] = Registry.lookup(Battleship.GameRegistry, "game_id")
      refute new_pid == pid
      assert Process.alive?(new_pid)
    end
  end
end
