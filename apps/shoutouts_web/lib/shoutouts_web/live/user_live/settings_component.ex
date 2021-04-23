defmodule ShoutoutsWeb.UserLive.SettingsComponent do
  @moduledoc """
  Live component wrapping a Account settings form.
  """
  use ShoutoutsWeb, :live_component

  require Logger

  alias Shoutouts.Accounts

  @impl true
  def update(%{current_user: current_user} = assigns, socket) do
    changeset =
      current_user
      |> Accounts.change_user()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"user" => params}, %{assigns: %{changeset: changeset}} = socket) do
    changeset =
      changeset.data
      |> Accounts.change_user(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event(
        "save",
        %{"user" => params},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    case Accounts.update_user(current_user, params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Settings updated successfully")
         |> push_redirect(to: Routes.user_index_path(socket, :show))}
      # NOTE: ^^^^^^^^^^^ the redirect above is to render the flash
      # Including the flash markup in the component renders the form incorrectly for some reason

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error("Error on query", changeset.errors)

        {:noreply,
         socket
         |> assign(:changeset, changeset)
         |> put_flash(:error, "Error creating shoutout")}
    end
  end
end
