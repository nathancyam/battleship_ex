defmodule Battleship.Server do
  use GenServer

  def start_link(game_id) do
    name = {:via, Registry, {Battleship.GameRegistry, game_id}}
    GenServer.start_link(__MODULE__, {:ok, game_id}, name: name)
  end

  def init(_args) do
    {:ok, :initial_state}
  end
end
