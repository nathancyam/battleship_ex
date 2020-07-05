defmodule BattleshipWeb.GameLive do
  use BattleshipWeb, :live_view

  alias Battleship.Core.{Board, Player, Ship}

  @typep point_val :: non_neg_integer() | nil
  @typep point :: {point_val(), point_val()}
  @typep selection :: {point(), point()}

  @empty_selection {{nil, nil}, {nil, nil}}

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:player, Player.new("Dude"))
      |> assign(:available_ships, Ship.all())
      |> assign(:selection, @empty_selection)
      |> assign(:ready?, false)

    {:ok, socket}
  end

  def handle_event("confirm_ready", _params, socket) do
    {:noreply, assign(socket, :ready?, true)}
  end

  def handle_event("tile", %{"row" => row, "column" => column}, socket) do
    %{selection: selection, available_ships: ships, player: player} = socket.assigns

    tuple = {String.to_integer(row), String.to_integer(column)}
    empty = {nil, nil}

    new_selection =
      case selection do
        {^empty, ^empty} ->
          {tuple, empty}

        {^tuple, ^empty} ->
          {empty, empty}

        {existing, ^empty} ->
          {existing, tuple}

        {existing, ^tuple} ->
          {existing, empty}

        _ ->
          selection
      end

    {ships_to_place, updated_player, new_selection} = do_placement(player, ships, new_selection)

    {:noreply,
     socket
     |> assign(:selection, new_selection)
     |> assign(:available_ships, ships_to_place)
     |> assign(:player, updated_player)}
  end

  def board_by_line(player), do: Enum.chunk_every(player.board.grid, 10)

  def first_ship(available_ships) do
    List.first(available_ships)
    |> Map.get(:type)
  end

  def ready?(available_ships), do: Enum.count(available_ships) == 0

  def to_emoji(item, selection) do
    {{start_x, start_y}, {end_x, end_y}} = selection

    case item do
      %Board.Coordinate{row: ^start_x, column: ^start_y} ->
        "⭕"

      %Board.Coordinate{row: ^end_x, column: ^end_y} ->
        "⭕"

      %Board.Coordinate{occupied_by: nil, hit?: false} ->
        "🌊"

      %Board.Coordinate{occupied_by: nil, hit?: true} ->
        "❌"

      %Board.Coordinate{occupied_by: _ship, hit?: true} ->
        "💥"

      %Board.Coordinate{occupied_by: _ship} ->
        "🚢"
    end
  end

  @spec do_placement(player :: Player.t(), ships :: [Ship.t()], selection :: selection()) ::
          {remaining_ships :: [Ship.t()], Player.placement_result(), selection :: selection()}
  defp do_placement(
         player,
         [ship | rest] = ships,
         {{start_x, start_y}, {end_x, end_y}} = selection
       )
       when start_x != nil and start_y != nil and end_x != nil and end_y != nil do
    case Player.place(player, ship, selection) do
      {:ok, player} ->
        {rest, player, @empty_selection}

      {:error, _reason, player} ->
        {ships, player, selection}
    end
  end

  defp do_placement(player, ships, selection), do: {ships, player, selection}
end
