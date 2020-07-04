defmodule Battleship.Core.Ship do
  defmodule PatrolBoat do
    defstruct []

    @type t :: %__MODULE__{}
  end

  defmodule Submarine do
    defstruct []

    @type t :: %__MODULE__{}
  end

  defmodule Destroyer do
    defstruct []

    @type t :: %__MODULE__{}
  end

  defmodule Battleship do
    defstruct []

    @type t :: %__MODULE__{}
  end

  defmodule Carrier do
    defstruct []

    @type t :: %__MODULE__{}
  end

  @type type_atom :: :patrol_boat | :submarine | :destroyer | :battleship | :carrier
  @type types :: PatrolBoat.t() | Submarine.t() | Destroyer.t() | Battleship.t() | Carrier.t()

  @spec new(ship_type :: type_atom()) :: types()
  def new(ship_type) do
    case ship_type do
      :patrol_boat -> %PatrolBoat{}
      :submarine -> %Submarine{}
      :destroyer -> %Destroyer{}
      :battleship -> %Battleship{}
      :carrier -> %Carrier{}
    end
  end

  @spec all() :: [types()]
  def all() do
    [:patrol_boat, :submarine, :destroyer, :battleship, :carrier]
    |> Enum.map(&new/1)
  end

  @spec atom(ship :: types()) :: type_atom()
  def atom(ship) do
    case ship do
      %PatrolBoat{} -> :patrol_boat
      %Submarine{} -> :submarine
      %Destroyer{} -> :destroyer
      %Battleship{} -> :battleship
      %Carrier{} -> :carrier
    end
  end

  @spec length(types()) :: pos_integer()
  def length(ship) do
    case ship do
      %PatrolBoat{} -> 2
      %Submarine{} -> 2
      %Destroyer{} -> 3
      %Battleship{} -> 4
      %Carrier{} -> 5
    end
  end
end
