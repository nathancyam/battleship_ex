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

  test "renders the game page", %{conn: conn} do
    {:ok, lv, disconnected_html} = live(conn, "/game/aaa")
    assert disconnected_html =~ "tile-0-0"
    assert render(lv) =~ "tile-0-0"
  end

  test "removes the available ships when placed", %{conn: conn} do
    {:ok, lv, _disconnected_html} = live(conn, "/game/aaa")

    html = lv |> element("#tile-0-0") |> render_click()
    assert html =~ "Please place the following ship: patrol_boat"

    html = lv |> element("#tile-0-1") |> render_click()
    refute html =~ "patrol"
    assert html =~ "Please place the following ship: submarine"
  end

  test "shows the ready button when all ships are placed", %{conn: conn} do
    {:ok, lv, _disconnected_html} = live(conn, "/game/aaa")
    {_lv, html} = complete_placement(lv)

    refute html =~ "Please place"
    assert html =~ "Ready"
  end

  test "updates game proces state when ready is clicked", %{conn: conn} do
    {:ok, lv, _disconnected_html} = live(conn, "/game/bbb")
    {lv, _html} = complete_placement(lv)
    lv |> element("#confirm-ready") |> render_click()
  end

  describe "game playthough" do
    setup do
      player1_conn = build_conn()
      player2_conn = build_conn()

      {:ok, player1, _} = live(player1_conn, "/game/bzz")
      {:ok, player2, _} = live(player2_conn, "/game/bzz")

      {player1, _} = complete_placement(player1)
      {player2, _} = complete_placement(player2)

      waiting_html = player1 |> element("#confirm-ready") |> render_click()
      refute waiting_html =~ "guess-"
      ready_html = player2 |> element("#confirm-ready") |> render_click()
      assert ready_html =~ "guess-"

      %{player1: player1, player2: player2}
    end

    test "shows error message informing placement can not occur mid game", %{
      player2: player2
    } do
      player2 |> element("#guess-1-0") |> render_click()

      error_html =
        player2 |> element("#tile-8-8") |> render_click()

      assert error_html =~ "Can not place ships while game is active!"
    end

    test "stops users from spam guessing", %{
      player1: player1,
      player2: player2
    } do
      player2 |> element("#guess-1-0") |> render_click()
      error_html = player2 |> element("#guess-1-0") |> render_click()

      assert error_html =~ "Not your turn!"
      player1 |> element("#guess-3-3") |> render_click()

      no_error_html = player2 |> render()

      refute no_error_html =~ "Not your turn!"
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

      {player2_html, player1_html} =
        Enum.zip(perfect, close)
        |> Enum.reduce({"", ""}, fn {tile1, tile2}, _ ->
          {player2 |> element(tile1) |> render_click(),
           player1 |> element(tile2) |> render_click()}
        end)

      assert player2_html =~ "You win!"
      refute player2_html =~ "You lose!"
      assert player1_html =~ "You lose!"
      refute player1_html =~ "You win!"
    end
  end
end
