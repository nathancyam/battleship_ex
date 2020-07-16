defmodule BattleshipWeb.GameLive do
  use BattleshipWeb, :live_view

  require Logger
  alias BattleshipWeb.{BoardLiveComponent, TileLiveComponent}
  alias BattleshipWeb.GameLive.{GuessAction, GuessResult, PlaceAction}
  alias Battleship.Core.{ConsoleRenderer, Game, Player, Ship}
  alias Battleship.Setup

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
        game_pid: nil,
        player: Player.new("Dude"),
        available_ships: Ship.all(),
        selection: @empty_selection,
        ready?: false,
        winner?: nil,
        designation: nil,
        game_in_session?: false,
        opponent: nil,
        hit_or_miss: nil,
        error_msg: nil,
        turn_lock?: false,
        player_joined?: false
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

  def handle_call(
        {:receive_from_opponent, game, opponent_process, from, opponent_guess},
        _from,
        socket
      ) do
    whoami = invert_designation(from)
    player = Map.get(game, whoami)

    default_assigns = [
      designation: whoami,
      player: player,
      error_msg: nil,
      opponent: opponent_process
    ]

    GuessResult.react_to_opponent_guess(player, opponent_guess)

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

  def handle_cast(:player_joined, socket) do
    Logger.info("another player has joined during setup phase")
    {:noreply, assign(socket, :player_joined?, true)}
  end

  def handle_cast(:player_left, socket) do
    Logger.info("opponent has left during setup phase")
    {:noreply, assign(socket, :player_joined?, false)}
  end

  def handle_cast({:receive_selection_from_opponent, tile, tiles}, socket) do
    {guess_tile, placement_tile} = tiles

    tile_id = TileLiveComponent.id_by_selection(tile)
    guess_id = "guess-#{tile_id}"
    place_id = "tile-#{tile_id}"

    # Update the guess board whether it was a hit or miss
    send_update(TileLiveComponent, id: guess_id, icon: ConsoleRenderer.to_emoji(guess_tile))

    # Update the player placement board with X or :boom:
    send_update(TileLiveComponent, id: place_id, icon: ConsoleRenderer.to_emoji(placement_tile))
    {:noreply, socket |> assign(:turn_lock?, false) |> assign(:error_msg, nil)}
  end

  def handle_cast({:update_assigns, assigns}, socket) do
    {:noreply, assign(socket, assigns)}
  end

  def handle_info(
        {:tile, "tile", from, %{"row" => _row, "column" => _column} = tile_selection},
        socket
      ) do
    if can_place?(socket) do
      {:noreply, PlaceAction.place(tile_selection, from, socket)}
    else
      {:noreply,
       socket
       |> assign(:error_msg, "Can not place ships while game is active!")}
    end
  end

  def handle_info(
        {:tile, "guess", _from, %{"row" => _row, "column" => _column} = tile_selection},
        socket
      ) do
    if not can_guess?(socket) do
      {:noreply, assign(socket, :error_msg, "Not your turn!")}
    else
      {:noreply,
       socket
       |> (&GuessAction.guess(&2, &1)).(tile_selection)}
    end
  end

  def empty_board() do
    for x <- Enum.to_list(0..9),
        y <- Enum.to_list(0..9) do
      %{row: x, column: y}
    end
    |> Enum.chunk_every(10)
    |> Enum.with_index()
  end

  def first_ship(available_ships),
    do:
      List.first(available_ships)
      |> Ship.label()

  def ship_name(ship), do: Ship.label(ship)

  def ready?(available_ships), do: Enum.count(available_ships) == 0

  def can_place?(%{assigns: %{game_in_session?: game_in_session?}}), do: game_in_session? == false

  @spec can_guess?(socket :: Phoenix.LiveView.Socket.t()) :: boolean()
  def can_guess?(socket), do: !socket.assigns.turn_lock?

  # @spec notify_opponent_of_game_change(res :: GuessResult.t()) ::
  #         Phoenix.LiveView.Socket.t()
  # defp notify_opponent_of_game_change(guess_result) do
  #   %{opponent: opponent, game: game, designation: des} = guess_result.socket.assigns
  #   GenServer.call(opponent, {:receive_from_opponent, game, self(), des, guess_result})
  #   guess_result.socket
  # end

  @spec invert_designation(atom()) :: atom()
  defp invert_designation(:player1), do: :player2
  defp invert_designation(:player2), do: :player1

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
    socket
    |> assign(:ready?, true)
    |> assign(:turn_lock?, false)
    |> assign(Setup.start_game(game_pid))
  end
end
