defmodule BattleshipWeb.GameLive do
  use BattleshipWeb, :live_view

  alias Battleship.Core.{Board, Game, GuessBoard, Player, Ship}
  alias Battleship.Setup

  @typep point_val :: non_neg_integer() | nil
  @typep point :: {point_val(), point_val()}
  @typep selection :: {point(), point()}

  @empty_selection {{nil, nil}, {nil, nil}}

  def mount(%{"id" => game_id}, _session, socket) do
    if connected?(socket) do
      Setup.Game.find_or_create_process(game_id)
      Setup.Game.register_player_socket(game_id, self())
    end

    socket =
      socket
      |> assign(
        game_id: game_id,
        player: Player.new("Dude"),
        available_ships: Ship.all(),
        selection: @empty_selection,
        ready?: false,
        winner?: nil,
        designation: nil,
        game: nil,
        opponent: nil,
        hit_or_miss: nil,
        error_msg: nil
      )

    {:ok, socket}
  end

  def handle_event("confirm_ready", _params, socket) do
    %{game_id: game_id, player: player} = socket.assigns

    new_socket =
      Setup.Game.toggle_player_readiness(game_id, self(), player)
      |> handle_readiness(socket)

    {:noreply, new_socket}
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
    if can_guess?(socket) do
      tuple = {String.to_integer(row), String.to_integer(column)}

      {:noreply,
       socket
       |> do_guess(tuple)
       |> notify_opponent_of_game_change()}
    else
      {:noreply, assign(socket, :error_msg, "Not your turn!")}
    end
  end

  def board_by_line(player, :board), do: Enum.chunk_every(player.board.grid, 10)
  def board_by_line(player, :guess), do: Enum.chunk_every(player.guess_board.grid, 10)

  @spec notify_opponent_of_game_change(socket :: Phoenix.LiveView.Socket.t()) ::
          Phoenix.LiveView.Socket.t()
  def notify_opponent_of_game_change(socket) do
    %{opponent: opponent, game: game, designation: des} = socket.assigns
    GenServer.call(opponent, {:receive_from_opponent, game, self(), des})
    socket
  end

  def handle_call({:receive_from_opponent, game, opponent_process, from}, _from, socket) do
    whoami = invert_designation(from)

    default_assigns = [
      designation: whoami,
      player: Map.get(game, whoami),
      game: game,
      error_msg: nil,
      opponent: opponent_process
    ]

    if game.over? do
      {:reply, :ok,
       socket
       |> assign(:winner?, false)
       |> assign(default_assigns)}
    else
      {:reply, :ok,
       socket
       |> assign(default_assigns)}
    end
  end

  def first_ship(available_ships),
    do:
      List.first(available_ships)
      |> Map.get(:type)

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

  @spec can_guess?(socket :: Phoenix.LiveView.Socket.t()) :: boolean()
  def can_guess?(socket) do
    %{game: game, designation: des} = socket.assigns
    game.active_turn == des
  end

  @spec do_guess(
          socket :: Phoenix.LiveView.Socket.t(),
          guess_type :: {non_neg_integer(), non_neg_integer()}
        ) :: Phoenix.LiveView.Socket.t()
  defp do_guess(socket, guess_tuple) do
    %{game: game, designation: des} = socket.assigns
    get_player = &Map.get(&1, des)

    case Game.guess(game, guess_tuple) do
      {:continue, hit_or_miss, updated_game} ->
        socket
        |> assign(:game, updated_game)
        |> assign(:player, get_player.(updated_game))
        |> assign(
          :hit_or_miss,
          if hit_or_miss == :hit do
            "You hit a target!"
          else
            "You missed!"
          end
        )

      {:game_over, winner, updated_game} ->
        player = get_player.(updated_game)

        socket
        |> assign(:game, updated_game)
        |> assign(:winner?, player == winner)
        |> assign(:player, player)
    end
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

  @spec handle_readiness(
          res :: {:ok, Setup.State.t(), pid()} | :not_started,
          socket :: Phoenix.LiveView.Socket.t()
        ) :: Phoenix.LiveView.Socket.t()
  defp handle_readiness({:ok, state, game_pid}, socket) do
    if Setup.State.game_ready?(state) do
      do_game_setup(game_pid, socket)
    else
      assign(socket, :ready?, !socket.assigns.ready?)
    end
  end

  defp handle_readiness(_, socket), do: assign(socket, :ready?, !socket.assigns.ready?)

  @spec do_game_setup(game_pid :: pid(), socket :: Phoenix.LiveView.Socket.t()) ::
          Phoenix.LiveView.Socket.t()
  defp do_game_setup(game_pid, socket) do
    {game, player1, player2} = Setup.start_game(game_pid)

    assigns =
      case {player1, player2} do
        {player1, player2} when player1 == self() ->
          [player: game.player1, designation: :player1, opponent: player2, game: game]

        {player1, player2} when player2 == self() ->
          [
            player: game.player2,
            designation: :player2,
            opponent: player1,
            game: Game.change_active_turn(game)
          ]
      end

    socket
    |> assign(:ready?, true)
    |> assign(assigns)
  end
end
