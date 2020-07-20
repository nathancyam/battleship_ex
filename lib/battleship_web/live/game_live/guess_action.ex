defmodule BattleshipWeb.GameLive.GuessAction do
  @moduledoc """
  Guess interactions from user with the LiveView socket.
  """

  require Logger

  import Phoenix.LiveView, only: [assign: 3]

  alias Phoenix.LiveView.Socket
  alias Battleship.Setup
  alias BattleshipWeb.GameLive.GuessResult

  @type point :: {non_neg_integer(), non_neg_integer()}

  @doc """
  For a given coordinate, update the game process, dispatch live view components
  updates to the player's guess board, and return the updated socket with the
  updated assigns. These assigns are:

  - `:hit_or_miss`. Did the selected coordinate land a hit on the opposing board?
  - `:turn_lock?`. Once the turn is taken, stop user actions until the next player
  has made their move

  If the selection ends with a game over (that is that the opponent no longer has
  any ships on their board), declare the owner of the socket the winner. The
  opponent will be notified that they have lost this exchange.
  """
  @spec guess(tile_selection :: map(), socket :: Socket.t()) :: Socket.t()
  def guess(%{"row" => row, "column" => column}, socket) do
    tuple = {String.to_integer(row), String.to_integer(column)}
    do_guess(socket, tuple)
  end

  @spec do_guess(
          socket :: Socket.t(),
          guess_type :: {non_neg_integer(), non_neg_integer()}
        ) :: Socket.t()
  defp do_guess(socket, guess_tuple) do
    %{designation: des, game_pid: pid} = socket.assigns
    get_player = &Map.get(&1, des)

    case Setup.guess(pid, guess_tuple) do
      {:continue, hit_or_miss, _updated_game} ->
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
          |> assign(:turn_lock?, true)

        case hit_or_miss do
          :hit ->
            GuessResult.hit(guess_tuple, new_socket)

          :miss ->
            GuessResult.miss(guess_tuple, new_socket)
        end
        |> GuessResult.update_selected_tile()

        new_socket

      {:game_over, winner, updated_game} ->
        player = get_player.(updated_game)

        socket
        |> assign(:winner?, player == winner)
        |> assign(:turn_lock?, true)
    end
  end
end
