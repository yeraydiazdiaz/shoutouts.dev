defmodule ShoutoutsWeb.ProjectLive.Show do
  use ShoutoutsWeb, :live_view

  alias Shoutouts.Repo
  alias Shoutouts.Accounts
  alias Shoutouts.Projects
  alias Shoutouts.Projects.Project
  alias Shoutouts.Shoutouts

  require Logger

  # ~2 years
  @required_user_longevity 60 * 60 * 24 * 365 * 2
  @owner_flagged_threshold 2

  @doc """
  Mount the project's LiveView with the :show action for registered users.

  Fetch the project, if it raises Ecto.NoResultsError Phoenix returns 404.
  """
  @impl true
  def mount(
        %{"owner" => owner, "name" => name},
        %{"current_user_id" => current_user_id},
        %{assigns: %{live_action: :show}} = socket
      ) do
    Logger.debug("Show project #{owner}/#{name}")
    # Flagged shoutouts are excluded from the preloading
    project = Projects.get_project_by_owner_and_name!(owner, name)
    current_user = Accounts.get_user!(current_user_id)
    user_is_owner = current_user_id == project.user_id
    shoutouts = Repo.preload(project.shoutouts, :user)
    user_repositories = get_user_repositories(current_user)

    {num_shoutouts, badge} = get_num_shoutouts_and_badge(project, shoutouts)

    flagged_shoutouts = Shoutouts.list_flagged_shoutouts_for_project(owner, name)

    user_shoutout = user_already_created_shoutout(shoutouts ++ flagged_shoutouts, current_user_id)

    user_is_banned_for_owner =
      not user_is_owner and
        Shoutouts.count_flagged_shoutouts_for_user_and_owner(
          current_user_id,
          project.user_id
        ) > 0

    user_is_banned_globally =
      not user_is_owner and
        Shoutouts.count_owners_flagged_user(current_user_id) > @owner_flagged_threshold

    user_account_too_young =
      Accounts.seconds_since_provider_joined(current_user) < @required_user_longevity

    {:ok,
     socket
     |> assign(:page_title, "#{owner}/#{name}")
     |> assign(:project, project)
     |> assign(:shoutouts, shoutouts)
     |> assign(:num_shoutouts, num_shoutouts)
     |> assign(:badge, badge)
     |> assign(:flagged_shoutouts, flagged_shoutouts)
     |> assign(:show_flagged_shoutouts, false)
     |> assign(:current_user, current_user)
     |> assign(:current_user_id, current_user_id)
     |> assign(:user_is_owner, user_is_owner)
     |> assign(:user_is_banned_for_owner, user_is_banned_for_owner)
     |> assign(:user_is_banned_globally, user_is_banned_globally)
     |> assign(:user_account_too_young, user_account_too_young)
     |> assign(
       :user_can_claim_project,
       project.user == nil and "#{project.owner}/#{project.name}" in user_repositories
     )
     |> assign(
       :disable_cta,
       user_account_too_young or user_is_banned_globally or user_is_banned_globally
     )
     |> assign(:user_shoutout, user_shoutout)}
  end

  # Mount the project's LiveView with the :show action for anonymous users.
  # Fetch the project, if it raises Ecto.NoResultsError Phoenix returns 404.
  @impl true
  def mount(
        %{"owner" => owner, "name" => name},
        _session,
        %{assigns: %{live_action: :show}} = socket
      ) do
    Logger.debug("Show project #{owner}/#{name}")
    project = Projects.get_project_by_owner_and_name!(owner, name)
    shoutouts = Repo.preload(project.shoutouts, :user)
    badge = Shoutouts.render_badge(length(shoutouts), 1.5)

    {:ok,
     socket
     |> assign(:page_title, "#{owner}/#{name}")
     |> assign(:project, project)
     |> assign(:shoutouts, shoutouts)
     |> assign(:num_shoutouts, length(shoutouts))
     |> assign(:badge, badge)
     |> assign(:flagged_shoutouts, [])
     |> assign(:show_flagged_shoutouts, false)
     |> assign(:current_user, nil)
     |> assign(:current_user_id, nil)
     |> assign(:user_is_owner, false)
     |> assign(:user_shoutout, nil)
     |> assign(:user_account_too_young, nil)}
  end

  # Mount the project's LiveView with the :edit action.
  # Fetch the project and raise forbidden if it does not belong to the current user.
  # Note this will be called twice, once on server render and another time on
  # LiveView render. This does mean we fetch the project twice, I'm not really
  # sure what the idiom is here, presumably we're supposed to mount and empty
  # state? Anyway, this view is not supposed to be loaded in the server.
  @impl true
  def mount(
        %{"id" => id},
        %{"current_user_id" => current_user_id},
        %{assigns: %{live_action: :edit}} = socket
      ) do
    Logger.info("Project #{id} for logged in user")

    with %Project{user_id: ^current_user_id} = project <- Projects.get_project!(id) do
      {:ok,
       socket
       |> assign(:page_title, "Edit #{project.owner}/#{project.name}")
       |> assign(:project, project)}
    else
      _ -> raise ShoutoutsWeb.ForbiddenError, "You are not authorized to see this page"
    end
  end

  # Mount the project's LiveView with the :add action to add shoutouts.
  # Fetch the project, if it raises Ecto.NoResultsError Phoenix returns 404.
  @impl true
  def mount(
        %{"owner" => owner, "name" => name},
        %{"current_user_id" => current_user_id},
        %{assigns: %{live_action: :add}} = socket
      ) do
    Logger.info("Add shoutout for project #{owner}/#{name}")
    current_user = Accounts.get_user!(current_user_id)
    project = Projects.get_project_by_owner_and_name!(owner, name)

    {:ok,
     socket
     |> assign(:page_title, "#{owner}/#{name}")
     |> assign(:current_user_id, current_user_id)
     |> assign(:current_user, current_user)
     |> assign(:project, project)
     |> assign(
       :user_shoutout,
       user_already_created_shoutout(project.shoutouts, current_user_id)
     )}
  end

  # 403 when anonymous users try to access the edit project page.
  @impl true
  def mount(_params, _session, _socket) do
    raise ShoutoutsWeb.ForbiddenError, "You are not authorized to see this page"
  end

  defp user_already_created_shoutout(shoutouts, user_id) do
    Enum.find(shoutouts, fn shoutout -> shoutout.user_id == user_id end)
  end

  @impl true
  def handle_event(
        "toggle_flagged",
        _params,
        %{assigns: %{show_flagged_shoutouts: show_flagged_shoutouts}} = socket
      ) do
    {:noreply, assign(socket, :show_flagged_shoutouts, not show_flagged_shoutouts)}
  end

  @impl true
  def handle_info(
        {:flag_shoutout, shoutout},
        %{
          assigns: %{
            project: project,
            shoutouts: shoutouts,
            flagged_shoutouts: flagged_shoutouts
          }
        } = socket
      ) do
    shoutouts = List.delete(shoutouts, shoutout)
    {:ok, shoutout} = Shoutouts.flag_shoutout(shoutout)

    {num_shoutouts, badge} = get_num_shoutouts_and_badge(project, shoutouts)

    {:noreply,
     socket
     |> assign(:num_shoutouts, num_shoutouts)
     |> assign(:badge, badge)
     |> assign(:shoutouts, shoutouts)
     |> assign(:flagged_shoutouts, [shoutout | flagged_shoutouts])
     |> put_flash(
       :info,
       "Sorry about that, this shoutout will be hidden from the project page and the user will be monitored."
     )}
  end

  @impl true
  def handle_info(
        {:unflag_shoutout, shoutout},
        %{
          assigns: %{
            project: project,
            shoutouts: shoutouts,
            flagged_shoutouts: flagged_shoutouts
          }
        } = socket
      ) do
    flagged_shoutouts = List.delete(flagged_shoutouts, shoutout)
    {:ok, shoutout} = Shoutouts.unflag_shoutout(shoutout)
    shoutouts = [shoutout | shoutouts]

    {num_shoutouts, badge} = get_num_shoutouts_and_badge(project, shoutouts)

    {:noreply,
     socket
     |> assign(:num_shoutouts, num_shoutouts)
     |> assign(:badge, badge)
     |> assign(:shoutouts, shoutouts)
     |> assign(:flagged_shoutouts, flagged_shoutouts)}
  end

  @impl true
  def handle_info(
        {:pin_shoutout, shoutout},
        %{assigns: %{shoutouts: shoutouts}} = socket
      ) do
    idx = Enum.find_index(shoutouts, &(&1.id == shoutout.id))
    shoutouts = List.delete_at(shoutouts, idx)
    {:ok, shoutout} = Shoutouts.pin_shoutout(shoutout)

    {:noreply,
     socket
     |> assign(:shoutouts, [shoutout | shoutouts])}
  end

  @impl true
  def handle_info(
        {:unpin_shoutout, shoutout},
        %{assigns: %{shoutouts: shoutouts}} = socket
      ) do
    idx = Enum.find_index(shoutouts, &(&1.id == shoutout.id))
    shoutouts = List.delete_at(shoutouts, idx)
    {:ok, shoutout} = Shoutouts.unpin_shoutout(shoutout)

    {:noreply,
     socket
     |> assign(:shoutouts, [shoutout | shoutouts])}
  end

  defp get_num_shoutouts_and_badge(project, shoutouts) do
    num_shoutouts =
      Enum.reduce(shoutouts, 0, fn t, acc ->
        if not project.pinned_only or t.pinned, do: acc + 1, else: acc
      end)

    {num_shoutouts, Shoutouts.render_badge(num_shoutouts, 1.5)}
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
