defmodule ShoutoutsWeb.ProjectController do
  @moduledoc """
  Project controller.
  """
  require Logger
  use ShoutoutsWeb, :controller
  alias Shoutouts.Shoutouts

  @doc """
  Badge endpoint, retrieves the shoutouts for the project and renders the badge.

  Note this endpoint does not use a view since we don't want to use layouts.
  """
  def badge(conn, %{"owner" => owner, "name" => name} = _params) do
    Logger.debug("Badge for project #{owner}/#{name}")

    case Shoutouts.badge_for_project(owner, name) do
      nil ->
        raise ShoutoutsWeb.NotFoundError, "Not found"

      badge ->
        conn
        |> put_resp_content_type("image/svg+xml")
        |> text(badge)
    end
  end
end
