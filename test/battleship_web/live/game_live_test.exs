defmodule BattleshipWeb.GameLiveTest do
  use BattleshipWeb.ConnCase

  import Phoenix.LiveViewTest
  import Battleship.GameSetup

  def complete_placement(lv) do
    tile_selectors = [
      # Patrol boat
      "4-6",
      "4-7",
      # Sub
      "9-4",
      "8-4",
      # Destroyer,
      "2-2",
      "2-4",
      # Battleship
      "5-4",
      "5-1",
      # Carrier
      "0-1",
      "0-5"
    ]

    for tile <- tile_selectors, selector = "#tile-#{tile}", reduce: {lv, ""} do
      {lv, _html} ->
        html = lv |> element(selector) |> render_click()
        {lv, html}
    end
  end

  def build_player_view(game_url) do
    player_conn = build_conn()
    {:ok, player, _} = live(player_conn, game_url)
    {player, _} = complete_placement(player)
    player
  end

  describe "when the game endpoint is hit" do
    test "renders the game page", %{conn: conn} do
      {:ok, lv, disconnected_html} = live(conn, "/game/aaa")
      assert disconnected_html =~ "tile-0-0"
      assert render(lv) =~ "tile-0-0"
    end
  end

  describe "when the ships are placed" do
    setup %{conn: conn} do
      {:ok, lv, _disconnected_html} = live(conn, "/game/aaa")
      %{view: lv}
    end

    test "toggles the tile selection", %{view: lv} do
      select_tile = fn ->
        lv |> element("#tile-0-0") |> render_click()
        lv |> element("#tile-0-0") |> render()
      end

      assert select_tile.() =~ "⭕"
      assert select_tile.() =~ "🌊"
    end

    test "removes the available ships when placed", %{view: lv} do
      html = lv |> element("#tile-0-0") |> render_click()
      assert html =~ "Please place the following ship: Patrol boat (length: 2)"

      lv |> element("#tile-0-1") |> render_click()
      html = lv |> element(".ship-placement") |> render()
      refute html =~ "patrol"
      assert html =~ "Please place the following ship: Submarine (length: 2)"

      refute has_element?(lv, "#confirm-ready")
    end

    test "shows the ready button when all ships are placed", %{view: lv} do
      {lv, _} = complete_placement(lv)

      html = lv |> element(".game-setup") |> render()
      refute html =~ "Please place"
      assert html =~ "Ready"
    end

    test "updates game proces state when ready is clicked", %{view: lv} do
      {lv, _html} = complete_placement(lv)
      lv |> element("#confirm-ready") |> render_click()
    end
  end

  describe "when players are setting up their boards" do
    test "each player sees that a new player has joined" do
      player1_conn = build_conn()
      player2_conn = build_conn()

      {:ok, player1, _} = live(player1_conn, "/game/baz")
      {:ok, player2, _} = live(player2_conn, "/game/baz")

      assert has_element?(player1, ".game-message")
      assert has_element?(player2, ".game-message")
    end
  end

  describe "when the game is being played" do
    setup do
      [player1, player2] =
        0..1
        |> Enum.map(fn _ -> build_player_view("/game/bzz") end)

      player1 |> element("#confirm-ready") |> render_click()
      ready_html = player2 |> element("#confirm-ready") |> render_click()
      assert ready_html =~ "guess-"

      %{player1: player1, player2: player2}
    end

    test "shows message informing player turns", %{player1: player1, player2: player2} do
      assert has_element?(player1, ".game-message", "Waiting on other player...")
      assert has_element?(player2, ".game-message", "Your turn")

      player2 |> element("#guess-1-0") |> render_click()

      assert has_element?(player1, ".game-message", "Your turn")
      assert has_element?(player2, ".game-message", "Waiting on other player...")
    end

    test "shows error message informing placement can not occur mid game", %{
      player2: player2
    } do
      player2 |> element("#guess-1-0") |> render_click()
      player2 |> element("#tile-8-8") |> render_click()

      error_html = player2 |> element(".game-error-msg") |> render()
      assert error_html =~ "Can not place ships while game is active!"
    end

    test "stops users from previously selected tiles", %{player1: player1, player2: player2} do
      player2 |> element("#guess-1-0") |> render_click()
      player1 |> element("#guess-1-0") |> render_click()

      player2
      |> element("#guess-1-0")
      |> render_click()

      assert has_element?(player2, ".game-error-msg", "Invalid tile selection!")
    end

    test "stops users from spam guessing", %{
      player1: player1,
      player2: player2
    } do
      player2 |> element("#guess-1-0") |> render_click()
      player2 |> element("#guess-1-2") |> render_click()

      assert has_element?(player2, ".game-error-msg", "Not your turn!")
      player1 |> element("#guess-3-3") |> render_click()
      refute has_element?(player2, ".game-error-msg")
    end

    test "runs through a game with player 2 winning", %{
      player1: player1,
      player2: player2
    } do
      to_tile = fn {x, y} -> "#guess-#{x}-#{y}" end

      perfect =
        perfect_selection()
        |> Enum.map(to_tile)

      close =
        close_selection()
        |> Enum.map(to_tile)

      Enum.zip(perfect, close)
      |> Enum.reduce({"", ""}, fn {tile1, tile2}, _ ->
        {player2 |> element(tile1) |> render_click(), player1 |> element(tile2) |> render_click()}
      end)

      assert has_element?(player2, ".game-over", "You win!")
      assert has_element?(player1, ".game-over", "You lose!")
    end
  end
end
