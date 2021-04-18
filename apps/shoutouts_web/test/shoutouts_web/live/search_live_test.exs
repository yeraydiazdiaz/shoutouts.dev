defmodule ShoutoutsWeb.SearchLiveTest do
  use ShoutoutsWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Shoutouts.Factory

  test "renders project by language summary if no query term", %{conn: conn} do
    s = Factory.insert(:shoutout)
    {:ok, _view, html} = live(conn, Routes.search_show_path(conn, :index))
    assert html =~ "Top projects by language"
    assert html =~ "#{s.project.owner}/#{s.project.name}"
  end

  test "renders no projects if not match on query arg term", %{conn: conn} do
    {:ok, _view, html} = live(conn, Routes.search_show_path(conn, :index, %{q: "foo"}))
    assert html =~ "Sorry, no projects match your query"
  end

  test "renders projects matching the query arg term", %{conn: conn} do
    s = Factory.insert(:shoutout)
    {:ok, _view, html} = live(conn, Routes.search_show_path(conn, :index, %{q: s.project.owner}))
    assert html =~ "#{s.project.owner}/#{s.project.name}"
  end

  test "renders projects matching the input in the form", %{conn: conn} do
    s = Factory.insert(:shoutout)
    {:ok, view, _html} = live(conn, Routes.search_show_path(conn, :index))
    assert view
    |> element("form")
    |> render_change(%{q: s.project.owner}) =~ "#{s.project.owner}/#{s.project.name}"
  end

  test "renders project by language summary when input in the form is deleted", %{conn: conn} do
    s = Factory.insert(:shoutout)
    {:ok, view, _html} = live(conn, Routes.search_show_path(conn, :index, %{q: s.project.owner}))
    html = view
    |> element("form")
    |> render_change(%{q: ""})
    assert html =~ "Top projects by language"
    refute html =~ "Sorry, no projects match your query"
  end
end
