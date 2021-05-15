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
  def badge(%Plug.Conn{assigns: %{project: project}} = conn, _params) do
    Logger.debug("Badge for project #{project.owner}/#{project.name}")

    conn
    |> put_resp_content_type("image/svg+xml")
    |> text(Shoutouts.render_badge(length(project.shoutouts)))
  end
end
