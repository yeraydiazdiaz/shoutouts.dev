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

    case Projects.project_exists?(owner, name) do
      false ->
        conn
        |> put_status(404)

      true ->
        conn
        |> put_resp_content_type("image/svg+xml")
        |> text(Shoutouts.badge_for_project(owner, name))
    end
  end
end
