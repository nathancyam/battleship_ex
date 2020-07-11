defmodule Battleship.Setup.ServerTest do
  use ExUnit.Case
  alias Battleship.Setup
  alias Battleship.Core.Player

  defmodule PlayerAgent do
    use GenServer

    def start_link([test_pid]) do
      GenServer.start_link(__MODULE__, {:ok, test_pid})
    end

    def init({:ok, test_pid}) do
      {:ok, test_pid}
    end

    def handle_cast(msg, state) do
      send(state, {self(), msg})
      {:noreply, state}
    end
  end

  def start_player_agent(name) do
    start_supervised({PlayerAgent, [self()]}, id: name, restart: :temporary)
  end

  setup do
    {:ok, pid} = Setup.start_link("game_id")
    assert Process.alive?(pid)
    %{server: pid}
  end

  describe "start_link/1" do
    test "starts the process with the registry", %{server: pid} do
      registry_res = Registry.lookup(Battleship.GameRegistry, "game_id")
      assert registry_res == [{pid, nil}]
    end
  end

  describe "register_player_socket/2" do
    test "adds the player to the state", %{server: svr} do
      {:ok, player} = start_player_agent("player1")
      {:ok, player2} = start_player_agent("player2")

      {:ok, state} = Setup.register_player_socket(svr, player)
      refute state.player1 == nil
      assert state.player2 == nil

      {:ok, state} = Setup.register_player_socket(svr, player2)
      refute state.player2 == nil

      assert_receive {^player, :player_joined}
      assert_receive {^player2, :player_joined}
    end
  end

  describe "clear_player/2" do
    test "invoked if the player's process dies", %{server: svr} do
      {:ok, player} = start_player_agent("playerA")
      {:ok, player2} = start_player_agent("playerB")

      Setup.register_player_socket(svr, player)
      Setup.register_player_socket(svr, player2)

      assert_receive {^player, :player_joined}
      assert_receive {^player2, :player_joined}

      Process.exit(player2, :kill)
      assert_receive {^player, :player_left}
    end
  end

  describe "toggle_player_ready/2" do
    test "toggles readiness", %{server: svr} do
      {:ok, player} = Agent.start(fn -> nil end)
      {:ok, _state} = Setup.register_player_socket(svr, player)

      player_struct = Player.new("test")
      {:ok, state, _} = Setup.toggle_player_ready(svr, player, player_struct)
      assert state.player1.ready?
    end
  end

  describe "supervisor" do
    test "restarts the process when killed" do
      {:ok, pid} = Battleship.GameSupervisor.start_game("game_supervisor")

      Process.exit(pid, :kill)
      Process.sleep(50)

      [{new_pid, nil}] = Registry.lookup(Battleship.GameRegistry, "game_supervisor")
      refute new_pid == pid
      assert Process.alive?(new_pid)
    end
  end
end
