defmodule BattleshipWeb.TileLiveComponent do
  use BattleshipWeb, :live_component

  def render(assigns) do
    ~L"""
    <div id="<%= @id %>" class="tile" phx-click="<%= @action %>" phx-value-row="<%= @tile.row %>" phx-value-column="<%= @tile.column %>" phx-target="<%= @myself %>">
      <%= @icon %>
    </div>
    """
  end

  def handle_event(action, %{"row" => row, "column" => column}, socket) do
    send(
      self(),
      {:tile, socket.assigns.action, socket.assigns.id,
       %{
         "row" => row,
         "column" => column
       }}
    )

    {:noreply, socket}
  end

  def id_by_selection({row, column}) do
    "#{row}-#{column}"
  end

  def preload(assigns) do
    Enum.map(
      assigns,
      fn
        %{action: "guess"} = assign ->
          Map.put(assign, :icon, "❓")

        %{action: "tile"} = assign ->
          Map.put(assign, :icon, "🌊")

        assign ->
          assign
      end
    )
  end
end
