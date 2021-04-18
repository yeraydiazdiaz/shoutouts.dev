defmodule ShoutoutsWeb.ProjectLive.Register do
  @moduledoc """
  LiveView for registering projects.
  """
  use ShoutoutsWeb, :live_view

  alias Shoutouts.Accounts
  alias Shoutouts.Projects.Registration
  alias Shoutouts.Projects

  require Logger

  @impl true
  def mount(params, session, socket) do
    changeset =
      Registration.changeset(%Registration{}, %{url_or_owner_name: Map.get(params, "q", "")})

    current_user_id = Map.get(session, "current_user_id")
    # TODO: auth puts the current_user in the connection, can we pick it up from there?
    current_user = if current_user_id, do: Accounts.get_user!(current_user_id), else: nil

    {:ok,
     socket
     |> assign(:current_user_id, current_user_id)
     |> assign(:current_user, current_user)
     |> assign(:changeset, changeset)
     |> assign(:disabled, true)}
  end

  @impl true
  def handle_event(
        "validate",
        %{"registration" => params},
        %{
          assigns: %{
            changeset: changeset,
            current_user: current_user
          }
        } = socket
      ) do
    user_repositories =
      Map.get(socket.assigns, :user_repositories, get_user_repositories(current_user))

    changeset =
      case Map.get(params, "url_or_owner_name") do
        "" -> Registration.changeset(%Registration{}, params)
        _ -> Registration.validate_changeset(changeset.data, params, user_repositories)
      end

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:user_repositories, user_repositories)
     |> assign(
       :disabled,
       Map.get(changeset.changes, :url_or_owner_name) in [nil, ""] or not changeset.valid?
     )}
  end

  @impl true
  def handle_event(
        "register",
        %{"registration" => params},
        %{assigns: %{changeset: changeset, current_user: current_user}} = socket
      ) do
    user_repositories =
      Map.get(socket.assigns, :user_repositories, get_user_repositories(current_user))

    changeset = Registration.validate_changeset(changeset.data, params, user_repositories)

    if changeset.valid? do
      case Projects.create_project(Map.from_struct(changeset.changes.provider_project)) do
        {:ok, project} ->
          {:noreply,
           socket
           |> put_flash(:info, "Project registered correctly")
           |> push_redirect(
             to: Routes.project_show_path(socket, :add, project.owner, project.name)
           )}

        {:error, %Ecto.Changeset{} = changeset} ->
          Logger.error("Error on query", changeset.errors)

          {:noreply,
           socket
           |> assign(:changeset, changeset)
           |> put_flash(:error, "Error registering project, please try again later")}
      end
    else
      {:noreply,
       socket
       |> assign(:changeset, changeset)}
    end
  end

  defp get_user_repositories(nil) do
    []
  end

  defp get_user_repositories(current_user) do
    case Projects.user_repositories(current_user) do
      {:ok, user_repositories} ->
        user_repositories

      {:error, _} ->
        Logger.error("Could not retrieve user repositories")
        []
    end
  end
end
