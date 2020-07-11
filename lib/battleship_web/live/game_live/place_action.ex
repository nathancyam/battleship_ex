defmodule BattleshipWeb.GameLive.PlaceAction do
  require Logger

  import Phoenix.LiveView, only: [assign: 3, send_update: 2]

  alias Phoenix.LiveView.Socket
  alias Battleship.Core.{Player, Ship}
  alias BattleshipWeb.TileLiveComponent

  @typep point_val :: non_neg_integer() | nil
  @typep point :: {point_val(), point_val()}
  @typep selection :: {point(), point()}
  @typep placement_result ::
           {remaining_ships :: [Ship.t()], tiles_changed :: [point()],
            player_res :: Player.placement_result(), selection :: selection()}

  @empty_selection {{nil, nil}, {nil, nil}}

  @spec place(tile_selection :: map(), from :: String.t(), socket :: Socket.t()) :: Socket.t()
  def place(%{"row" => _row, "column" => _column} = tile_selection, from, socket) do
    %{available_ships: ships, player: player} = socket.assigns
    {_old_selection, selection, unselect?} = create_selection(tile_selection, socket)

    {ships_to_place, tiles_changed, updated_player, new_selection} =
      do_placement(player, ships, selection)

    if new_selection == @empty_selection do
      Logger.info(
        "selection=#{inspect(selection)} made full selection, setting selected tiles to ships"
      )

      for selection <- tiles_changed,
          id = TileLiveComponent.id_by_selection(selection),
          tile_id = "tile-#{id}" do
        send_update(TileLiveComponent, id: tile_id, icon: "🚢")
      end
    else
      icon =
        if unselect? do
          "🌊"
        else
          "⭕"
        end

      send_update(TileLiveComponent, id: from, icon: icon)
    end

    socket
    |> assign(:selection, new_selection)
    |> assign(:available_ships, ships_to_place)
    |> assign(:player, updated_player)
  end

  @spec create_selection(selection :: map(), socket :: Socket.t()) ::
          {old :: selection(), new :: selection(), unselect? :: boolean()}
  defp create_selection(%{"row" => row, "column" => column}, %{assigns: %{selection: selection}}) do
    tuple = {String.to_integer(row), String.to_integer(column)}
    empty = {nil, nil}

    {new_selection, unselect?} =
      case selection do
        {^empty, ^empty} ->
          {{tuple, empty}, false}

        {^tuple, ^empty} ->
          {{empty, empty}, true}

        {existing, ^empty} ->
          {{existing, tuple}, false}

        {existing, ^tuple} ->
          {{existing, empty}, true}

        _ ->
          {selection, false}
      end

    {selection, new_selection, unselect?}
  end

  @spec do_placement(player :: Player.t(), ships :: [Ship.t()], selection :: selection()) ::
          placement_result()
  defp do_placement(
         player,
         [ship | rest] = ships,
         {{start_x, start_y}, {end_x, end_y}} = selection
       )
       when start_x != nil and start_y != nil and end_x != nil and end_y != nil do
    case Player.place(player, ship, selection) do
      {:ok, tiles_changed, player} ->
        {rest, tiles_changed, player, @empty_selection}

      {:error, _reason, player} ->
        {ships, [], player, selection}
    end
  end

  defp do_placement(player, ships, selection), do: {ships, [], player, selection}
end
