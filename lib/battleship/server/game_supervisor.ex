defmodule Battleship.GameSupervisor do
  use DynamicSupervisor

  alias Battleship.Server

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_game(game_id) do
    DynamicSupervisor.start_child(__MODULE__, {Server, game_id})
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
