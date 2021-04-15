defmodule ShoutoutsWeb.ProjectLiveTest do
  use ShoutoutsWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Shoutouts.Accounts.User
  alias Shoutouts.Factory
  alias ShoutoutsWeb.TestHelpers

  def login_user(conn, %User{} = user) do
    conn
    |> assign(:ueberauth_auth, TestHelpers.auth_for_user(user))
    |> get(Routes.auth_path(conn, :callback, :github))
  end

  test "renders project title, description, and no shoutouts copy", %{conn: conn} do
    p = Factory.insert(:project)
    {:ok, _view, html} = live(conn, Routes.project_show_path(conn, :show, p.owner, p.name))
    assert html =~ "#{p.owner}/#{p.name}"
    assert html =~ p.description
    assert html =~ "No shoutouts yet"
  end

  test "projects with shoutouts render a badge", %{conn: conn} do
    p = Factory.insert(:project)
    s = Factory.insert(:shoutout, %{project: p})
    {:ok, view, html} = live(conn, Routes.project_show_path(conn, :show, p.owner, p.name))
    assert html =~ "#{p.owner}/#{p.name}"
    assert html =~ p.description
    assert html =~ s.text
    assert html =~ s.user.name
    assert view |> element("svg") |> render() =~ "shoutouts"
  end

  test "anonymous user sare prompted to log in to leave a shoutout", %{conn: conn} do
    p = Factory.insert(:project)
    {:ok, view, _html} = live(conn, Routes.project_show_path(conn, :show, p.owner, p.name))

    assert element(view, "a", "Log in to leave a shoutout") |> render() =~
             Routes.auth_path(conn, :request, :github)
  end

  test "logged in users are prompted to leave the first shoutout", %{conn: conn} do
    u = Factory.insert(:user)
    conn = login_user(conn, u)
    p = Factory.insert(:project)
    {:ok, view, _html} = live(conn, Routes.project_show_path(conn, :show, p.owner, p.name))

    assert element(view, "a", "Be the first!") |> render() =~
             Routes.project_show_path(conn, :add, p.owner, p.name)
  end

  test "logged in users are prompted to leave a shoutout", %{conn: conn} do
    p = Factory.insert(:project)
    Factory.insert(:shoutout, %{project: p})
    u = Factory.insert(:user)
    conn = login_user(conn, u)
    {:ok, view, _html} = live(conn, Routes.project_show_path(conn, :show, p.owner, p.name))

    assert element(view, "a", "Add your shoutout") |> render() =~
             Routes.project_show_path(conn, :add, p.owner, p.name)
  end

  test "logged in users that have already left a shoutout are not prompted to leave another",
       %{conn: conn} do
    owner = Factory.insert(:user, %{name: "owner"})
    p = Factory.insert(:project, %{user: owner})
    s = Factory.insert(:shoutout, %{project: p})
    conn = login_user(conn, s.user)
    {:ok, _view, html} = live(conn, Routes.project_show_path(conn, :show, p.owner, p.name))

    assert html =~ s.text
    assert html =~ s.user.name
    refute html =~ "Add your shoutout"
  end

  # owners
  # a pin/flag copy is rendered

  # pinning
  # each shoutout has a pin/flag set of buttons
  # pinning a shouout updates it and is placed on top

  # flagging
  # flagging a shoutout updates it and is hidden, a "show flagged" button is rendered
  # clicking the show flagged button renders the flagged shoutouts
  # clicking on the flag shoutout on flagged shoutouts updates and "show flagged" button disappears
end
