defmodule ShoutoutsWeb.PageControllerTest do
  use ShoutoutsWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Open Source"
  end
end
