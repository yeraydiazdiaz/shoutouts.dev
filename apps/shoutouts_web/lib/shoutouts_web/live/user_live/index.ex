defmodule ShoutoutsWeb.UserLive.Index do
  use ShoutoutsWeb, :live_view

  require Logger

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
    {:ok,
     get_user(socket, current_user_id)
     |> assign(:page_title, "Account settings")}
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
     |> assign(:page_title, "Your projects")
     |> assign(:projects, Projects.project_summary_for_username(user.username))}
  end

  # Entry point for shoutouts list.
  @impl true
  def mount(
        _params,
        %{"current_user_id" => current_user_id},
        %{assigns: %{live_action: :shoutouts}} = socket
      ) do
    %{assigns: %{current_user: user}} = socket = get_user(socket, current_user_id)

    {:ok,
     socket
     |> assign(:page_title, "Your shoutouts")
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
     |> assign(:page_title, "Edit project")
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

    case Projects.user_repositories(user) do
      {:ok, possible_repos} ->
        {existing_projects, claimable_projects} =
          possible_repos
          |> Enum.map(&String.split(&1, "/"))
          |> Projects.list_with_owners_and_names()
          |> Enum.reduce({[], []}, fn p, {e, c} ->
            if p.user_id != nil, do: {[p | e], c}, else: {e, [p | c]}
          end)

        existing_project_names = Enum.map(existing_projects, &Projects.name_with_owner/1)
        claimable_project_names = Enum.map(claimable_projects, &Projects.name_with_owner/1)

        repos_to_be_added =
          Enum.filter(possible_repos, fn repo ->
            repo not in existing_project_names and repo not in claimable_project_names
          end)

        {:ok,
         socket
         |> assign(:current_user, user)
         |> assign(:repos, repos_to_be_added)
         |> assign(:existing_projects, existing_projects)
         |> assign(:claimable_projects, claimable_projects)}

      {:error, error} ->
        Logger.error("Could not retrieve user repos", error: error)

        {:ok,
         socket
         |> put_flash(:error, "Could not retrieve your repositories, please try again later")
         |> redirect(to: Routes.user_index_path(socket, :projects))}
    end
  end

  # Entry point for project delete.
  @impl true
  def mount(
        %{"id" => project_id},
        %{"current_user_id" => current_user_id},
        %{assigns: %{live_action: :delete}} = socket
      ) do
    socket = get_user(socket, current_user_id)

    {:ok,
     socket
     |> assign(:page_title, "Delete project")
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
        # TODO: this can be %{} if the user does not select any projects
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

  # Claim projects form submit entry point.
  # Assigns the user's ID to the selected projects.
  @impl true
  def handle_event(
        "claim",
        %{"projects" => projects},
        %{
          assigns: %{
            current_user: current_user,
            claimable_projects: claimable_projects,
            existing_projects: existing_projects
          }
        } = socket
      ) do
    Logger.debug("Claiming projects")

    claimed_projects =
      Map.keys(projects)
      |> Enum.map(&String.split(&1, "/"))
      |> Enum.reduce([], fn [owner, name], acc ->
        {:ok, project} =
          Enum.find(claimable_projects, fn p -> p.owner == owner and p.name == name end)
          |> Projects.claim_project(current_user)

        [project | acc]
      end)

    new_existing_projects = existing_projects ++ claimed_projects
    claimed_project_ids = for p <- claimed_projects, do: p.id
    new_claimable_projects = for p <- claimable_projects, p.id not in claimed_project_ids, do: p

    {:noreply,
     socket
     |> put_flash(:info, "#{length(claimed_project_ids)} project(s) claimed successfully")
     |> assign(:existing_projects, new_existing_projects)
     |> assign(:claimable_projects, new_claimable_projects)}
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

  # Fetches and assigns the current user to the socket if necessary
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
    Map.keys(repos)
    |> Stream.map(&String.split(&1, "/"))
    |> Stream.map(fn [owner, name] ->
      Task.async(fn -> Projects.project_info(current_user, owner, name) end)
    end)
    |> Stream.map(&Task.await/1)
    |> Stream.map(fn {:ok, project_info} ->
      Projects.create_project(current_user, Map.from_struct(project_info))
    end)
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
