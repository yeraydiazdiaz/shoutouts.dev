defmodule ShoutoutsWeb.SponsorsControllerTest do
  use ShoutoutsWeb.ConnCase

  test "shows sponsors", %{conn: conn} do
    conn = get(conn, Routes.sponsors_path(conn, :show))
    assert html = html_response(conn, 200)
    assert html =~ "Sponsors"
    assert html =~ "AppSignal"
  end
end