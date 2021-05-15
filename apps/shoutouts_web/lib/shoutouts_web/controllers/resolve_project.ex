defmodule ShoutoutsWeb.ResolveProject do
  @moduledoc """
  """
  import Plug.Conn

  require Logger

  alias Shoutouts.Projects

  def init(opts), do: opts

  def call(%Plug.Conn{params: %{"name" => name, "owner" => owner}} = conn, _opts) do
    Logger.info("Resolving project")

    case Projects.resolve_project_by_owner_and_name(owner, name) do
      {:error, :no_such_project} ->
        conn |> send_resp(:not_found, "Not found") |> halt()

      {:ok, %Projects.Project{owner: ^owner, name: ^name} = project} ->
        conn |> assign(:project, project)

      {:ok, project} ->
        conn
        |> put_resp_header(
          "location",
          ShoutoutsWeb.Router.Helpers.project_path(conn, :badge, project.owner, project.name)
        )
        |> send_resp(:moved_permanently, "Moved permanently")
        |> halt()
    end
  end

  def call(%Plug.Conn{} = conn, _opts) do
    conn
  end
end