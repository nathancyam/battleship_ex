defmodule BattleshipWeb.PageLive do
  use BattleshipWeb, :live_view

  alias Battleship.Form.New

  @impl true
  def mount(_params, _session, socket) do
    changeset = New.changeset(%New{}, %{})
    {:ok, assign(socket, query: "", results: %{}, changeset: changeset)}
  end

  @impl true
  def handle_event("suggest", %{"q" => query}, socket) do
    {:noreply, assign(socket, results: search(query), query: query)}
  end

  def handle_event("validate", %{"new" => params}, socket) do
    changeset =
      New.changeset(%New{}, params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("submit", %{"new" => params}, socket) do
    changeset =
      New.changeset(%New{}, params)
      |> Map.put(:action, :insert)

    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, data} ->
        {:noreply,
         socket
         |> put_flash(:info, "Joining or creating game")
         |> push_redirect(to: Routes.game_path(socket, :index, data.game_id))}

      {:error, error_changeset} ->
        {:noreply, assign(socket, :changeset, error_changeset)}
    end
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    case search(query) do
      %{^query => vsn} ->
        {:noreply, redirect(socket, external: "https://hexdocs.pm/#{query}/#{vsn}")}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "No dependencies found matching \"#{query}\"")
         |> assign(results: %{}, query: query)}
    end
  end

  defp search(query) do
    if not BattleshipWeb.Endpoint.config(:code_reloader) do
      raise "action disabled when not in development"
    end

    for {app, desc, vsn} <- Application.started_applications(),
        app = to_string(app),
        String.starts_with?(app, query) and not List.starts_with?(desc, ~c"ERTS"),
        into: %{},
        do: {app, vsn}
  end
end
