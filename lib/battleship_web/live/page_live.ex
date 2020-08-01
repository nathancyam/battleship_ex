defmodule BattleshipWeb.PageLive do
  use BattleshipWeb, :live_view

  alias Battleship.Form.New

  @impl true
  def mount(_params, _session, socket) do
    changeset = New.changeset(%New{}, %{})
    {:ok, assign(socket, query: "", results: %{}, changeset: changeset)}
  end

  @impl true
  def handle_event("validate", %{"new" => params}, socket) do
    changeset =
      New.changeset(%New{}, params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl true
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
end
