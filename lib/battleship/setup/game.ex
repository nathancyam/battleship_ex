defmodule Battleship.Setup.Game do
  alias Battleship.{GameSupervisor, Setup}
  alias Battleship.Core.Player

  @spec find_or_create_process(game_id :: String.t()) :: pid()
  def find_or_create_process(game_id) do
    case GameSupervisor.start_game(game_id) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end

  @spec find_process(game_id :: String.t()) :: nil | pid()
  def find_process(game_id) do
    case Registry.lookup(Battleship.GameRegistry, game_id) do
      [{pid, nil}] -> pid
      _ -> nil
    end
  end

  @spec register_player_socket(game_id :: String.t(), socket_pid :: pid()) :: :ok | :not_started
  def register_player_socket(game_id, socket_pid) do
    case find_process(game_id) do
      nil ->
        :not_started

      pid when is_pid(pid) ->
        Setup.register_player_socket(pid, socket_pid)
        :ok
    end
  end

  @spec toggle_player_readiness(game_id :: String.t(), socket_pid :: pid(), player :: Player.t()) ::
          :not_started | {:ok, Setup.State.t(), pid()}
  def toggle_player_readiness(game_id, socket_pid, player) do
    case find_process(game_id) do
      nil ->
        :not_started

      pid when is_pid(pid) ->
        Setup.toggle_player_ready(pid, socket_pid, player)
    end
  end
end
