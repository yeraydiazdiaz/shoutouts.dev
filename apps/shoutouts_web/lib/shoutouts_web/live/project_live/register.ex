defmodule ShoutoutsWeb.ProjectLive.Register do
  @moduledoc """
  LiveView for adding unclaimed projects.
  """
  use ShoutoutsWeb, :live_view

  alias Shoutouts.Repo
  alias Shoutouts.Accounts
  alias Shoutouts.Projects
  alias Shoutouts.Projects.Project

  require Logger

  def mount(_params, session, socket) do
    {:ok,
     socket
     |> assign(:current_user_id, Map.get(session, "current_user_id"))}
  end
end
