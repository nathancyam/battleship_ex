defmodule BattleshipWeb.GameLive.GuessResult do
  import Phoenix.LiveView, only: [send_update: 2]

  alias Phoenix.LiveView.Socket
  alias Battleship.Core.{ConsoleRenderer, Player}
  alias BattleshipWeb.GameLive.GuessAction
  alias BattleshipWeb.TileLiveComponent

  defstruct [:hit_result, :guess, :socket]

  @type t :: %__MODULE__{
          hit_result: :miss | :hit,
          guess: GuessAction.point()
        }

  @spec hit(guess :: GuessAction.point(), socket :: Socket.t()) :: t()
  def hit(guess, _socket) do
    %__MODULE__{hit_result: :hit, guess: guess}
  end

  @spec miss(guess :: GuessAction.point(), socket :: Socket.t()) :: t()
  def miss(guess, _socket) do
    %__MODULE__{hit_result: :miss, guess: guess}
  end

  @spec update_selected_tile(result :: t()) :: t()
  def update_selected_tile(%__MODULE__{hit_result: hit_result, guess: guess} = result) do
    icon =
      case hit_result do
        :hit ->
          "💥"

        :miss ->
          "🌊"
      end

    tile_id = TileLiveComponent.id_by_selection(guess)
    send_update(TileLiveComponent, id: "guess-#{tile_id}", icon: icon)
    result
  end

  @spec react_to_opponent_guess(player :: Player.t(), result :: t()) :: t()
  def react_to_opponent_guess(player, %__MODULE__{} = result) do
    {guess_tile, placement_tile} = Player.tiles_at_boards(player, result.guess)

    tile_id = TileLiveComponent.id_by_selection(result.guess)
    guess_id = "guess-#{tile_id}"
    place_id = "tile-#{tile_id}"

    # Update the guess board whether it was a hit or miss
    send_update(TileLiveComponent, id: guess_id, icon: ConsoleRenderer.to_emoji(guess_tile))

    # Update the player placement board with X or :boom:
    send_update(TileLiveComponent, id: place_id, icon: ConsoleRenderer.to_emoji(placement_tile))
    result
  end
end
