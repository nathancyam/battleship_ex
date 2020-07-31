defmodule Battleship.Form.New do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: nil,
          player_name: String.t() | nil,
          game_id: String.t() | nil
        }

  embedded_schema do
    field :player_name
    field :game_id
  end

  @spec changeset(form :: t(), params :: map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = form, params) do
    form
    |> cast(params, [:player_name, :game_id])
    |> validate_required([:player_name])
    |> validate_length(:player_name, min: 5)
    |> validate_length(:game_id, min: 8)
  end
end
