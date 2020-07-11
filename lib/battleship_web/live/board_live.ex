defmodule BattleshipWeb.BoardLiveComponent do
  use BattleshipWeb, :live_component

  alias Battleship.Core.{Board, GuessBoard}
  alias BattleshipWeb.TileLiveComponent

  def render(assigns) do
    ~L"""
    <%= for {line, count} <- @board do %>
      <div id="<%= line_id(@action, count) %>" phx-update="replace">
      <%= for tile <- line do %>
        <%= live_component @socket, TileLiveComponent, id: tile_id(@action, tile), action: @action, tile: tile %>
      <% end %>
      </div>
    <% end %>
    """
  end

  def line_id(action, line), do: "#{action}-line-#{line}"

  def tile_id(action, tile), do: "#{action}-#{tile.row}-#{tile.column}"
end
