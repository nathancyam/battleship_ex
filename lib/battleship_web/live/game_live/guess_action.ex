defmodule BattleshipWeb.GameLive.GuessAction do
  require Logger

  import Phoenix.LiveView, only: [assign: 3]

  alias Phoenix.LiveView.Socket
  alias Battleship.Core.{Game}
  alias Battleship.Setup
  alias BattleshipWeb.GameLive.GuessResult

  @type point :: {non_neg_integer(), non_neg_integer()}

  @spec guess(tile_selection :: map(), socket :: Socket.t()) :: GuessResult.t()
  def guess(%{"row" => row, "column" => column}, socket) do
    tuple = {String.to_integer(row), String.to_integer(column)}
    do_guess(socket, tuple)
  end

  @spec do_guess(
          socket :: Phoenix.LiveView.Socket.t(),
          guess_type :: {non_neg_integer(), non_neg_integer()}
        ) :: GuessResult.t()
  defp do_guess(socket, guess_tuple) do
    %{designation: des, game_pid: pid} = socket.assigns
    get_player = &Map.get(&1, des)

    case Setup.guess(pid, guess_tuple) do
      {:continue, hit_or_miss, updated_game} ->
        new_socket =
          socket
          |> assign(
            :hit_or_miss,
            if hit_or_miss == :hit do
              "You hit a target!"
            else
              "You missed!"
            end
          )

        case hit_or_miss do
          :hit ->
            GuessResult.hit(guess_tuple, new_socket)
            |> GuessResult.update_selected_tile()

          :miss ->
            GuessResult.miss(guess_tuple, new_socket)
            |> GuessResult.update_selected_tile()
        end

        new_socket

      {:game_over, winner, updated_game} ->
        player = get_player.(updated_game)

        socket
        |> assign(:winner?, player == winner)
    end
  end
end
