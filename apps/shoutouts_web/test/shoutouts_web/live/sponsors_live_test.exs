defmodule ShoutoutsWeb.SponsorsLiveTest do
  use ShoutoutsWeb.ConnCase

  import Phoenix.LiveViewTest

  test "shows sponsors", %{conn: conn} do
    {:ok, _view, html} = live(conn, Routes.sponsors_show_path(conn, :index))
    assert html =~ "Sponsors"
    assert html =~ "AppSignal"
  end
end