defmodule Battleship.Setup.PlayerStatus do
  alias Battleship.Core.Player

  defstruct [:pid, :ready?, :player]

  @type t :: %__MODULE__{
          pid: pid(),
          ready?: boolean(),
          player: Player.t() | nil
        }

  @spec new(player_pid :: pid()) :: t()
  def new(player_pid) do
    %__MODULE__{
      pid: player_pid,
      ready?: false,
      player: nil
    }
  end
end
