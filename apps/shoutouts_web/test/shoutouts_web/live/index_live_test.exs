defmodule ShoutoutsWeb.IndexLiveTest do
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

  test "renders links and register CTA for anonymous users", %{conn: conn} do
    {:ok, _view, html} = live(conn, Routes.index_show_path(conn, :show))
    assert html =~ Routes.search_show_path(conn, :index)
    assert html =~ Routes.auth_path(conn, :request, :github)
    assert html =~ Routes.faq_show_path(conn, :index)
  end

  test "renders links and register projects CTA for logged in users", %{conn: conn} do
    user = Factory.insert(:user)
    conn = login_user(conn, user)
    {:ok, _view, html} = live(conn, Routes.index_show_path(conn, :show))
    assert html =~ Routes.search_show_path(conn, :index)
    assert html =~ Routes.user_index_path(conn, :add)
    assert html =~ Routes.faq_show_path(conn, :index)
  end

  test "renders existing shoutouts", %{conn: conn} do
    s1 = Factory.insert(:shoutout)
    # Force s2 to appear first respecting logic in shoutouts_for_top_projects
    p1 = Factory.insert(:project)
    s2 = Factory.insert(:shoutout, %{project: p1, pinned: true})
    _ = Factory.insert(:shoutout, %{project: p1})
    {:ok, view, _html} = live(conn, Routes.index_show_path(conn, :show))

    assert view |> element(".opacity-100") |> render() =~ s2.text
    assert view |> element(".opacity-0") |> render() =~ s1.text
  end

  test "sending :carrousel_timeout changes visible shoutouts", %{conn: conn} do
    s1 = Factory.insert(:shoutout)
    # Force s2 to appear first respecting logic in shoutouts_for_top_projects
    p1 = Factory.insert(:project)
    s2 = Factory.insert(:shoutout, %{project: p1, pinned: true})
    _ = Factory.insert(:shoutout, %{project: p1})
    {:ok, view, _html} = live(conn, Routes.index_show_path(conn, :show))

    assert view |> element(".opacity-100") |> render() =~ s2.text
    assert view |> element(".opacity-0") |> render() =~ s1.text

    send(view.pid, :carrousel_timeout)

    assert view |> element(".opacity-100") |> render() =~ s1.text
    assert view |> element(".opacity-0") |> render() =~ s2.text
  end

  test "clicking carrousel buttons changes visible shoutouts and prevents timeout", %{conn: conn} do
    s1 = Factory.insert(:shoutout)
    # Force s2 to appear first respecting logic in shoutouts_for_top_projects
    p1 = Factory.insert(:project)
    s2 = Factory.insert(:shoutout, %{project: p1, pinned: true})
    _ = Factory.insert(:shoutout, %{project: p1})
    {:ok, view, _html} = live(conn, Routes.index_show_path(conn, :show))

    assert view |> element(".opacity-100") |> render() =~ s2.text
    assert view |> element(".opacity-0") |> render() =~ s1.text

    view |> element(".bg-dim") |> render_click()
    assert view |> element(".opacity-100") |> render() =~ s1.text

    # timeout switching does nothing once user has clicked
    send(view.pid, :carrousel_timeout)

    assert view |> element(".opacity-100") |> render() =~ s1.text
  end
end
