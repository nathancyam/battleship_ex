defmodule BattleshipWeb.BoardLiveComponent do
  @moduledoc """
  Component that renders an empty board initially. Throughout the game
  progress, their tile are updated asynchronouly by sending the tile
  the relevant change message.
  """

  use BattleshipWeb, :live_component

  alias BattleshipWeb.TileLiveComponent

  @type tile :: %{row: non_neg_integer(), column: non_neg_integer()}

  def render(assigns) do
    ~L"""
    <div id="game--grid-<%= @action %>" class="game-grid">
    <%= for {line, count} <- empty_board() do %>
      <div id="<%= line_id(@action, count) %>">
      <%= for tile <- line do %>
        <%= live_component @socket, TileLiveComponent, id: tile_id(@action, tile), action: @action, tile: tile %>
      <% end %>
      </div>
    <% end %>
    </div>
    """
  end

  @spec empty_board() :: [{tile(), non_neg_integer()}]
  def empty_board() do
    for x <- Enum.to_list(0..9),
        y <- Enum.to_list(0..9) do
      %{row: x, column: y}
    end
    |> Enum.chunk_every(10)
    |> Enum.with_index()
  end

  @spec line_id(action :: atom(), line :: String.t()) :: String.t()
  def line_id(action, line), do: "#{action}-line-#{line}"

  def tile_id(action, tile), do: "#{action}-#{tile.row}-#{tile.column}"
end
