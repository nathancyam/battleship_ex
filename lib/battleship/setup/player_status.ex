defmodule Battleship.Setup.PlayerStatus do
  alias Battleship.Core.Player

  defstruct [:view, :ready?, :player]

  @type t :: %__MODULE__{
          view: pid(),
          ready?: boolean(),
          player: Player.t() | nil
        }

  @spec new(player_view :: pid()) :: t()
  def new(player_view) do
    %__MODULE__{
      view: player_view,
      ready?: false,
      player: nil
    }
  end
end
