defmodule BattleshipWeb.GameLive do
  use BattleshipWeb, :live_view

  alias Battleship.Core.{Board, GuessBoard, Player, Ship}
  alias Battleship.Server

  @typep point_val :: non_neg_integer() | nil
  @typep point :: {point_val(), point_val()}
  @typep selection :: {point(), point()}

  @empty_selection {{nil, nil}, {nil, nil}}

  def mount(%{"id" => game_id}, _session, socket) do
    if connected?(socket) do
      Server.Game.find_or_create_process(game_id)
      Server.Game.register_player_socket(game_id, self())
    end

    socket =
      socket
      |> assign(:game_id, game_id)
      |> assign(:player, Player.new("Dude"))
      |> assign(:available_ships, Ship.all())
      |> assign(:selection, @empty_selection)
      |> assign(:ready?, false)
      |> assign(:designation, nil)
      |> assign(:game, nil)
      |> assign(:opponent, nil)

    {:ok, socket}
  end

  def handle_event("confirm_ready", _params, socket) do
    %{game_id: game_id, player: player} = socket.assigns
    Server.Game.toggle_player_readiness(game_id, self(), player)
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

  def handle_event("guess", %{"row" => row, "column" => column}, socket) do
    %{game: game, opponent: opponent, designation: des} = socket.assigns
    tuple = {String.to_integer(row), String.to_integer(column)}
    {_next, _hit, updated_game} = Battleship.Core.Game.guess(game, tuple)
    GenServer.call(opponent, {:receive_from_opponent, updated_game, self(), des})

    {:noreply,
     socket
     |> assign(:game, updated_game)
     |> assign(:player, Map.get(updated_game, des))}
  end

  def board_by_line(player, :board), do: Enum.chunk_every(player.board.grid, 10)
  def board_by_line(player, :guess), do: Enum.chunk_every(player.guess_board.grid, 10)

  def first_ship(available_ships) do
    List.first(available_ships)
    |> Map.get(:type)
  end

  def ready?(available_ships), do: Enum.count(available_ships) == 0

  def to_emoji(item, selection) do
    {{start_x, start_y}, {end_x, end_y}} = selection

    case item do
      %GuessBoard.Coordinate{guess_result: :hit} ->
        "💥"

      %GuessBoard.Coordinate{guess_result: :miss} ->
        "🌊"

      %GuessBoard.Coordinate{guess_result: :unknown} ->
        "❓"

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

  def handle_call({:start_game, game, {_process, opponent_process}}, _from, socket) do
    {:reply, :ok,
     socket
     |> assign(:game, game)
     |> assign(:designation, :player1)
     |> assign(:player, game.player1)
     |> assign(:opponent, opponent_process)}
  end

  def handle_call({:receive_from_opponent, game, opponent_process, from}, _from, socket) do
    whoami = invert_designation(from)

    {:reply, :ok,
     socket
     |> assign(:designation, whoami)
     |> assign(:player, Map.get(game, whoami))
     |> assign(:game, game)
     |> assign(:opponent, opponent_process)}
  end

  defp invert_designation(:player1), do: :player2
  defp invert_designation(:player2), do: :player1

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
