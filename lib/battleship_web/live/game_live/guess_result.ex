defmodule BattleshipWeb.GameLive.GuessResult do
  import Phoenix.LiveView, only: [send_update: 2]

  alias Phoenix.LiveView.Socket
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
end
