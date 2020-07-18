defmodule BattleshipWeb.TileLiveComponent do
  use BattleshipWeb, :live_component

  def render(assigns) do
    ~L"""
    <div id="<%= @id %>" class="tile" phx-click="<%= @action %>" phx-value-row="<%= @tile.row %>" phx-value-column="<%= @tile.column %>" phx-target="<%= @myself %>">
      <%= @icon %>
    </div>
    """
  end

  def handle_event(_action, %{"row" => row, "column" => column}, socket) do
    if click_allowed?(socket.assigns.action, socket.assigns.icon) do
      send(
        self(),
        {:tile, socket.assigns.action, socket.assigns.id,
         %{
           "row" => row,
           "column" => column
         }}
      )
    else
      send(self(), :invalid_selection)
    end

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

  defp click_allowed?("guess", icon) do
    icon == "❓"
  end

  defp click_allowed?("tile", icon) do
    icon != "🚢"
  end
end
