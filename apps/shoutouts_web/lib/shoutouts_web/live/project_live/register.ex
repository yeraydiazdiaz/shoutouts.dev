defmodule ShoutoutsWeb.ProjectLive.Register do
  @moduledoc """
  LiveView for registering projects.
  """
  use ShoutoutsWeb, :live_view

  alias Shoutouts.Projects.Registration

  require Logger

  @impl true
  def mount(_params, session, socket) do
    changeset = Registration.changeset(%Registration{}, %{url_or_owner_name: ""})
    {:ok,
     socket
     |> assign(:current_user_id, Map.get(session, "current_user_id"))
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"registration" => params}, %{assigns: %{changeset: changeset}} = socket) do
    changeset = Registration.changeset(changeset.data, params)
    {:noreply, assign(socket, :changeset, changeset)}
  end
end
