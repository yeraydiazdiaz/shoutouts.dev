defmodule ShoutoutsWeb.UserLive.Index do
  use ShoutoutsWeb, :live_view

  require Logger

  alias Shoutouts.GitHubApp
  alias Shoutouts.Accounts
  alias Shoutouts.Projects
  alias Shoutouts.Shoutouts

  @doc """
  Entry point for account settings.
  """
  @impl true
  def mount(
        _params,
        %{"current_user_id" => current_user_id},
        %{assigns: %{live_action: :show}} = socket
      ) do
    {:ok, get_user(socket, current_user_id)}
  end

  # Entry point for project list.
  @impl true
  def mount(
        _params,
        %{"current_user_id" => current_user_id},
        %{assigns: %{live_action: :projects}} = socket
      ) do
    %{assigns: %{current_user: user}} = socket = get_user(socket, current_user_id)

    {:ok,
     socket
     |> assign(:projects, Projects.project_summary_for_username(user.username))}
  end

  # Entry point for project list.
  @impl true
  def mount(
        _params,
        %{"current_user_id" => current_user_id},
        %{assigns: %{live_action: :shoutouts}} = socket
      ) do
    %{assigns: %{current_user: user}} = socket = get_user(socket, current_user_id)

    {:ok,
     socket
     |> assign(:shoutouts, Shoutouts.list_shoutouts_for_user(user.username))}
  end

  # Entry point for project edit.
  @impl true
  def mount(
        %{"id" => project_id},
        %{"current_user_id" => current_user_id},
        %{assigns: %{live_action: :edit_project}} = socket
      ) do
    socket = get_user(socket, current_user_id)

    {:ok,
     socket
     |> assign(:project, Projects.get_project!(project_id))}
  end

  # Add new projects for user.
  # Retrieves the user's owned repositories, the user selects one or more.
  # Once selected we retrieve the project information and create the projects.
  # Note we cannot access conn.current_user as we only have access to the socket.
  @impl true
  def mount(
        _params,
        %{"current_user_id" => current_user_id},
        %{assigns: %{live_action: :add}} = socket
      ) do
    Logger.debug("Add projects for logged in user")
    %{assigns: %{current_user: user}} = socket = get_user(socket, current_user_id)

    possible_repos =
      GitHubApp.client()
      |> GitHubApp.user_repositories(user.username)

    case possible_repos do
      {:ok, possible_repos} ->
        existing_repos =
          possible_repos
          |> Enum.map(&String.split(&1, "/"))
          |> Projects.list_with_owners_and_names()

        repos_to_be_added =
          Enum.filter(possible_repos, fn repo ->
            repo not in Enum.map(existing_repos, &Projects.name_with_owner/1)
          end)

        {:ok,
         socket
         |> assign(:current_user, user)
         |> assign(:repos, repos_to_be_added)
         |> assign(:existing_repos, existing_repos)}

      {:error, error} ->
        Logger.error("Could not retrieve user repos", error)
        {:ok, socket |> put_flash(:error, "Could not retrieve user repositories")}
    end
  end

  # Entry point for project edit.
  @impl true
  def mount(
        %{"id" => project_id},
        %{"current_user_id" => current_user_id},
        %{assigns: %{live_action: :delete}} = socket
      ) do
    socket = get_user(socket, current_user_id)

    {:ok,
     socket
     |> assign(:project, Projects.get_project!(project_id))}
  end

  # Unknown action.
  @impl true
  def mount(_params, %{"current_user_id" => _current_user_id}, _socket) do
    raise ShoutoutsWeb.NotFoundError, "Not found"
  end

  # Anonymous user entry point.
  @impl true
  def mount(_params, _, socket) do
    {:ok,
     socket
     |> put_flash(:error, "You must log in first to access the account preferences.")
     |> redirect(to: "/")}
  end

  @doc """
  Add projects form submit entry point.

  Creates projects and redirects to the projects list succesful.
  """
  @impl true
  def handle_event(
        "submit",
        %{"repos" => repos},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    Logger.debug("Adding projects")

    case create_projects(repos, current_user) do
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to add projects")}

      {:ok, projects} ->
        {:noreply,
         socket
         |> put_flash(:info, "#{length(projects)} project(s) added successfully")
         |> redirect(to: Routes.user_index_path(socket, :projects))}
    end
  end

  # Delete project event handler.
  @impl true
  def handle_event(
        "delete",
        _params,
        %{assigns: %{current_user: _current_user, project: project}} = socket
      ) do
    Logger.debug("Deleting projects")
    {:ok, project} = Projects.delete_project(project)

    {:noreply,
     socket
     |> put_flash(:info, "Project \"#{Projects.name_with_owner(project)}\" deleted successfully")
     |> redirect(to: Routes.user_index_path(socket, :projects))}
  end

  defp get_user(socket, current_user_id) do
    case socket.assigns[:current_user] do
      nil ->
        user = Accounts.get_user!(current_user_id)
        assign(socket, :current_user, user)

      u ->
        assign(socket, :current_user, u)
    end
  end

  defp create_projects(repos, current_user) do
    client = GitHubApp.client()

    Map.keys(repos)
    |> Stream.map(&String.split(&1, "/"))
    |> Stream.map(fn [owner, name] ->
      Task.async(fn -> GitHubApp.project_info(client, owner, name) end)
    end)
    |> Stream.map(&Task.await/1)
    |> Stream.map(fn {:ok, attrs} -> Projects.create_project(current_user, attrs) end)
    |> Enum.reduce(
      {:ok, []},
      fn {result, project}, {end_result, projects} ->
        case {end_result, result} do
          {:error, error} ->
            Logger.error(error)
            {:error, projects}

          # Error on changeset
          {:ok, :error} ->
            Logger.error(project.errors)
            {:error, projects}

          {:ok, :ok} ->
            {:ok, projects ++ [project]}
        end
      end
    )
  end
end
