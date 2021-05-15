defmodule ShoutoutsWeb.ResolveProject do
  @moduledoc """
  Plug to resolve a project from the passed owner/name parameters.

  If a project matches the owner/name we assign it to the connection,
  if a project's previous owner/names match we redirect and halt,
  otherwise we return 404 and halt.
  """
  import Plug.Conn

  require Logger

  alias Shoutouts.Projects

  def init(opts), do: opts

  def call(%Plug.Conn{params: %{"owner" => owner, "name" => name}} = conn, _opts) do
    case Projects.resolve_project_by_owner_and_name(owner, name) do
      {:error, :no_such_project} ->
        conn |> send_resp(:not_found, "Not found") |> halt()

      {:ok, %Projects.Project{owner: ^owner, name: ^name} = project} ->
        conn |> assign(:project, project)

      {:ok, project} ->
        conn
        |> put_resp_header(
          "location",
          conn.request_path
          |> String.replace("/#{owner}/#{name}", "/#{project.owner}/#{project.name}")
        )
        |> send_resp(:moved_permanently, "Moved permanently")
        |> halt()
    end
  end

  def call(%Plug.Conn{} = conn, _opts) do
    conn
  end
end
