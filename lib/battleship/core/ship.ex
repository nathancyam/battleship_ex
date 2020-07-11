defmodule Battleship.Core.Ship do
  @type type_atom :: :patrol_boat | :submarine | :destroyer | :battleship | :carrier

  @type t :: %__MODULE__{
          type: type_atom()
        }

  @valid_types [:patrol_boat, :submarine, :destroyer, :battleship, :carrier]

  defstruct [:type]

  @spec new(ship_type :: type_atom()) :: t()
  def new(ship_type) do
    unless Enum.member?(@valid_types, ship_type) do
      raise ArgumentError, message: "Invalid ship type given"
    end

    %__MODULE__{type: ship_type}
  end

  def all() do
    @valid_types
    |> Enum.map(&new/1)
  end

  def label(ship) do
    name =
      ship.type
      |> Atom.to_string()
      |> String.replace("_", " ")
      |> String.capitalize()

    "#{name} (length: #{__MODULE__.length(ship)})"
  end

  @spec atom(ship :: t()) :: type_atom()
  def atom(%{type: type}), do: type

  @spec length(ship :: t()) :: pos_integer()
  def length(%{type: :patrol_boat}), do: 2
  def length(%{type: :submarine}), do: 2
  def length(%{type: :destroyer}), do: 3
  def length(%{type: :battleship}), do: 4
  def length(%{type: :carrier}), do: 5
end
