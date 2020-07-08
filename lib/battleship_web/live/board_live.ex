defmodule BattleshipWeb.BoardLiveComponent do
  use BattleshipWeb, :live_component

  alias Battleship.Core.{Board, GuessBoard}

  def render(assigns) do
    ~L"""
    <%= for {line, count} <- @board do %>
      <div id="<%= line_id(@action, count) %>" phx-update="replace">
      <%= for tile <- line do %>
        <div id="<%= tile_id(@action, tile) %>" class="tile" phx-click="<%= @action %>" phx-value-row="<%= tile.row %>" phx-value-column="<%= tile.column %>" phx-update="replace">
          <%= to_emoji(tile, @selection) %>
        </div>
      <% end %>
      </div>
    <% end %>
    """
  end

  def tile_id(action, tile), do: "#{action}-#{tile.row}-#{tile.column}"

  def line_id(action, line), do: "#{action}-line-#{line}"

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
end
