defmodule ShoutoutsWeb.ProjectController do
  @moduledoc """
  Project controller.
  """
  require Logger
  use ShoutoutsWeb, :controller
  alias Shoutouts.Projects
  alias Shoutouts.Shoutouts

  @doc """
  Badge endpoint, retrieves the shoutouts for the project and renders the badge.

  Note this endpoint does not use a view since we don't want to use layouts.
  """
  def badge(conn, %{"owner" => owner, "name" => name} = _params) do
    Logger.debug("Badge for project #{owner}/#{name}")

    case Projects.resolve_project_by_owner_and_name(owner, name) do
      {:error, :no_such_project} ->
        conn
        |> put_status(:not_found)
        |> text("Project not found")

      {:ok, %Projects.Project{owner: ^owner, name: ^name}} -> 
        conn
        |> put_resp_content_type("image/svg+xml")
        |> text(Shoutouts.badge_for_project(owner, name))

      {:ok, project} -> 
        conn
        |> put_status(:moved_permanently)
        |> put_resp_header("location", Routes.project_path(conn, :badge, project.owner, project.name))
        |> text("Moved permanently")
    end
  end
end
