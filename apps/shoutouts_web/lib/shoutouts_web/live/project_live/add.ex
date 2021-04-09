defmodule ShoutoutsWeb.ProjectLive.Add do
  @moduledoc """
  LiveView for adding unclaimed projects.
  """
  use ShoutoutsWeb, :live_view

  alias Shoutouts.Repo
  alias Shoutouts.Accounts
  alias Shoutouts.Projects
  alias Shoutouts.Projects.Project

  require Logger
end
