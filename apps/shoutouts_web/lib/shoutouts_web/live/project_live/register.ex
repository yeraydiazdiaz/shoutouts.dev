defmodule ShoutoutsWeb.ProjectLive.Register do
  @moduledoc """
  LiveView for registering projects.
  """
  use ShoutoutsWeb, :live_view

  alias Shoutouts.Projects.Registration
  alias Shoutouts.Projects

  require Logger

  @impl true
  def mount(_params, session, socket) do
    changeset = Registration.changeset(%Registration{}, %{url_or_owner_name: ""})

    {:ok,
     socket
     |> assign(:current_user_id, Map.get(session, "current_user_id"))
     |> assign(:changeset, changeset)
     |> assign(:disabled, true)}
  end

  @impl true
  def handle_event(
        "validate",
        %{"registration" => params},
        %{assigns: %{changeset: changeset}} = socket
      ) do
    changeset =
      case Map.get(params, "url_or_owner_name") do
        "" -> Registration.changeset(%Registration{}, params)
        _ -> Registration.validate_changeset(changeset.data, params)
      end

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(
       :disabled,
       Map.get(changeset.changes, :url_or_owner_name) in [nil, ""] or not changeset.valid?
     )}
  end

  @impl true
  def handle_event(
        "register",
        %{"registration" => params},
        %{assigns: %{changeset: changeset}} = socket
      ) do
    changeset = Registration.validate_changeset(changeset.data, params)
    case Projects.create_project(Map.from_struct(changeset.changes.provider_project)) do
      {:ok, project} ->
        {:noreply,
         socket
         |> put_flash(:info, "Project registered correctly")
         |> push_redirect(to: Routes.project_show_path(socket, :add, project.owner, project.name))}

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error("Error on query", changeset.errors)

        {:noreply,
         socket
         |> assign(:changeset, changeset)
         |> put_flash(:error, "Error registering project, please try again later")}
    end
  end
end
