defmodule ShoutoutsWeb.ProjectControllerTest do
  use ShoutoutsWeb.ConnCase

  alias Shoutouts.Factory

  test "shows badge with shoutout count", %{conn: conn} do
    project = Factory.insert(:project)
    Factory.insert(:shoutout, project: project)
    conn = get(conn, Routes.project_path(conn, :badge, project.owner, project.name))
    assert conn.status == 200

    assert Enum.find(conn.resp_headers, fn {h, v} ->
             h == "content-type" and v == "image/svg+xml; charset=utf-8"
           end) != nil

    assert conn.resp_body =~ "1</text>"
  end

  test "returns 404 for non-existing projects", %{conn: conn} do
    conn = get(conn, Routes.project_path(conn, :badge, "nope", "doesntexist"))
    assert conn.status == 404
  end

  test "returns 304 when requestion an old owner/name for project", %{conn: conn} do
    project = Factory.insert(:project, previous_owner_names: ["me/oldname"])
    conn = get(conn, Routes.project_path(conn, :badge, "me", "oldname"))
    assert conn.status == 301
    {_, location} = Enum.find(conn.resp_headers, fn {h, _} -> h == "location" end)
    assert location == Routes.project_path(conn, :badge, project.owner, project.name)
  end
end
