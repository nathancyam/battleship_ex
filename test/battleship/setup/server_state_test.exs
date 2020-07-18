defmodule Battleship.Setup.StateTest do
  use ExUnit.Case
  alias Battleship.Setup.State

  describe "add_player/2" do
    setup do
      %{state: State.new()}
    end

    test "adds the first player when not found", %{state: state} do
      {:ok, pid} = Agent.start(fn -> nil end)
      {:ok, new_state} = State.add_player(state, pid)

      assert new_state.player1.view == pid
      refute new_state.player1.ready?

      assert new_state.player2 == nil
    end

    test "adds the second player when the first one exists", %{state: state} do
      {:ok, pid} = Agent.start(fn -> nil end)
      {:ok, second} = Agent.start(fn -> nil end)
      {:ok, new_state} = State.add_player(state, pid)
      {:ok, new_state} = State.add_player(new_state, second)

      assert new_state.player1.view == pid
      refute new_state.player1.ready?

      assert new_state.player2.view == second
      refute new_state.player2.ready?
    end

    test "return game full error", %{state: state} do
      {:ok, pid} = Agent.start(fn -> nil end)
      {:ok, second} = Agent.start(fn -> nil end)
      {:ok, third} = Agent.start(fn -> nil end)

      {:ok, new_state} = State.add_player(state, pid)
      {:ok, new_state} = State.add_player(new_state, second)
      assert {:error, :game_full, new_state} = State.add_player(new_state, third)
    end
  end
end
