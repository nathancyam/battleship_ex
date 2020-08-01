defmodule BattleshipWeb.PageLive do
  use BattleshipWeb, :live_view

  alias Battleship.Form.New

  @login_types %{email: :string, password: :string}

  @impl true
  def mount(_params, session, socket) do
    changeset = New.changeset(%New{}, %{})

    login_changeset =
      {%{email: nil, password: nil}, @login_types}
      |> Ecto.Changeset.cast(%{}, Map.keys(@login_types))

    {:ok,
     assign(socket,
       active_form: "create_form",
       trigger_action: false,
       game_changeset: changeset,
       login_changeset: login_changeset
     )}
  end

  @impl true
  def handle_event("login_form", _params, socket) do
    if socket.assigns.active_form == "login_form" do
      {:noreply, socket}
    else
      {:noreply, assign(socket, :active_form, "login_form")}
    end
  end

  @impl true
  def handle_event("create_form", _params, socket) do
    if socket.assigns.active_form == "create_form" do
      {:noreply, socket}
    else
      {:noreply, assign(socket, :active_form, "create_form")}
    end
  end

  @impl true
  def handle_event("validate", %{"new" => params}, socket) do
    changeset =
      New.changeset(%New{}, params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, game_changeset: changeset)}
  end

  def handle_event("login", %{"user" => params}, socket) do
    changeset =
      {%{}, @login_types}
      |> Ecto.Changeset.cast(params, Map.keys(@login_types))
      |> Ecto.Changeset.validate_required([:email, :password])

    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, _} ->
        {:noreply, assign(socket, login_changeset: changeset, trigger_action: true)}

      {:error, changeset} ->
        {:noreply, assign(socket, login_changeset: changeset)}
    end
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
        {:noreply, assign(socket, :game_changeset, error_changeset)}
    end
  end
end
