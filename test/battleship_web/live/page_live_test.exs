defmodule BattleshipWeb.PageLiveTest do
  use BattleshipWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "when the user enters input on the form" do
    setup %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      %{view: view}
    end

    test "shows error when player name is less than 5 characters", %{view: view} do
      params = %{"game_id" => "", "player_name" => "aaa"}

      assert view
             |> element("form")
             |> render_change(%{"new" => params}) =~ "should be at least 5 character(s)"
    end

    test "shows error when game ID is entered with less than 8 characters", %{view: view} do
      params = %{"game_id" => "aaa", "player_name" => "abcdefg"}

      assert view
             |> element("form")
             |> render_change(%{"new" => params}) =~ "should be at least 8 character(s)"
    end

    test "redirects when data is valid", %{view: view} do
      params = %{"game_id" => "valid_game_id", "player_name" => "abcdefg"}

      view
      |> element("form")
      |> render_submit(%{"new" => params})

      flash = assert_redirect(view, "/game/valid_game_id")
      assert flash["info"] == "Joining or creating game"
    end
  end

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Battleship"
    assert render(page_live) =~ "Battleship"
  end
end
