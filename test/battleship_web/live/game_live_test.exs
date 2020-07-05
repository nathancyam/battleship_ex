defmodule BattleshipWeb.GameLiveTest do
  use BattleshipWeb.ConnCase

  import Phoenix.LiveViewTest

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

    tile_selectors = [
      # Patrol boat
      "0-1",
      "0-2",
      # Sub
      "1-2",
      "1-3",
      # Destroyer,
      "2-3",
      "2-5",
      # Battleship
      "3-5",
      "3-8",
      # Carrier
      "5-0",
      "5-4"
    ]

    {_lv, html} =
      for tile <- tile_selectors, selector = "#tile-#{tile}", reduce: {lv, ""} do
        {lv, _html} ->
          html = lv |> element(selector) |> render_click()
          {lv, html}
      end

    refute html =~ "Please place"
    assert html =~ "Ready"
  end
end
