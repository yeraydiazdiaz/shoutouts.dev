defmodule ShoutoutsWeb.ProjectLiveTest do
  use ShoutoutsWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Shoutouts.Accounts.User
  alias Shoutouts.Factory
  alias Shoutouts.Shoutouts
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

  describe "logged in users" do
    test "are prompted to leave the first shoutout", %{conn: conn} do
      u = Factory.insert(:user)
      conn = login_user(conn, u)
      p = Factory.insert(:project)
      {:ok, view, _html} = live(conn, Routes.project_show_path(conn, :show, p.owner, p.name))

      assert element(view, "a", "Be the first!") |> render() =~
               Routes.project_show_path(conn, :add, p.owner, p.name)
    end

    test "are prompted to leave a shoutout", %{conn: conn} do
      p = Factory.insert(:project)
      Factory.insert(:shoutout, %{project: p})
      u = Factory.insert(:user)
      conn = login_user(conn, u)
      {:ok, view, _html} = live(conn, Routes.project_show_path(conn, :show, p.owner, p.name))

      assert element(view, "a", "Add your shoutout") |> render() =~
               Routes.project_show_path(conn, :add, p.owner, p.name)
    end

    test "that have already left a shoutout are not prompted to leave another",
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

    test "whose provider account is too young are not prompted to leave another",
         %{conn: conn} do
      owner = Factory.insert(:user, %{name: "owner"})
      p = Factory.insert(:project, %{user: owner})
      u = Factory.insert(:user, %{provider_joined_at: DateTime.utc_now()})
      conn = login_user(conn, u)
      {:ok, _view, html} = live(conn, Routes.project_show_path(conn, :show, p.owner, p.name))

      refute html =~ "Add your shoutout"
      assert html =~ "Sorry, only users with a provider account older than 2 years are allowed to add shoutouts"
    end

    test "that have left a flagged shoutout on another of the user's projects are not prompted to leave another",
         %{conn: conn} do
      owner = Factory.insert(:user, %{name: "owner"})
      other_project = Factory.insert(:project, %{user: owner})
      p = Factory.insert(:project, %{user: owner})
      u = Factory.insert(:user)
      Factory.insert(:shoutout, %{project: other_project, user: u, flagged: true})
      conn = login_user(conn, u)
      {:ok, _view, html} = live(conn, Routes.project_show_path(conn, :show, p.owner, p.name))

      refute html =~ "Add your shoutout"
      assert html =~ "The owner of this project has flagged a shoutout on another one of their projects"
    end

    test "that have left a flagged shoutouts on more than 2 other projects are not prompted to leave a shoutout",
         %{conn: conn} do
      u = Factory.insert(:user)
      1..3  # > @owner_flagged_threshold in show.ex
      |> Enum.each(fn _i ->
        p = Factory.insert(:project)
        Factory.insert(:shoutout, %{project: p, user: u, flagged: true})
      end)
      p = Factory.insert(:project)
      conn = login_user(conn, u)
      {:ok, _view, html} = live(conn, Routes.project_show_path(conn, :show, p.owner, p.name))

      refute html =~ "Add your shoutout"
      assert html =~ "Several owners have flagged your shoutouts"
    end
  end

  describe "project owners" do
    test "pin and flag buttons are rendered on each shoutout", %{conn: conn} do
      p = Factory.insert(:project)
      Factory.insert(:shoutout, %{project: p})
      conn = login_user(conn, p.user)
      {:ok, view, html} = live(conn, Routes.project_show_path(conn, :show, p.owner, p.name))

      refute html =~ "Add your shoutout"
      assert html =~ "We hope you enjoy the shoutouts for your project"
      assert has_element?(view, "button[title=\"Click to pin this shoutout\"]")
      assert has_element?(view, "button[title=\"Click to flag this shoutout\"]")
    end

    test "pinning a shoutout updates it and renders it at the top", %{conn: conn} do
      p = Factory.insert(:project)
      s1 = Factory.insert(:shoutout, %{project: p})
      s2 = Factory.insert(:shoutout, %{project: p})
      conn = login_user(conn, p.user)
      {:ok, view, _html} = live(conn, Routes.project_show_path(conn, :show, p.owner, p.name))

      assert view |> element(".relative:first-of-type") |> render() =~ s2.text
      assert view |> element(".relative:last-of-type") |> render() =~ s1.text
      element(view, "##{s1.id} button[title=\"Click to pin this shoutout\"]") |> render_click()
      render(view)

      assert view |> element(".relative:first-of-type") |> render() =~ s1.text
      assert view |> element(".relative:last-of-type") |> render() =~ s2.text
      assert Shoutouts.get_shoutout!(s1.id).pinned
      assert has_element?(view, "button[title=\"Click to unpin this shoutout\"]")
    end

    test "flagging a shoutout updates it and hides it behind a button", %{conn: conn} do
      p = Factory.insert(:project)
      s1 = Factory.insert(:shoutout, %{project: p})
      s2 = Factory.insert(:shoutout, %{project: p})
      conn = login_user(conn, p.user)
      {:ok, view, _html} = live(conn, Routes.project_show_path(conn, :show, p.owner, p.name))

      assert view |> element(".relative:first-of-type") |> render() =~ s2.text
      assert view |> element(".relative:last-of-type") |> render() =~ s1.text
      element(view, "##{s1.id} button[title=\"Click to flag this shoutout\"]") |> render_click()
      render(view)

      assert Shoutouts.get_shoutout!(s1.id).flagged
      assert view |> element(".relative:first-of-type") |> render() =~ s2.text
      refute view |> render() =~ s1.text
      assert has_element?(view, "button", "Show 1 flagged shoutout")
    end

    test "clicking show flagged shoutouts shows flagged shoutouts", %{conn: conn} do
      p = Factory.insert(:project)
      s1 = Factory.insert(:shoutout, %{project: p, flagged: true})
      s2 = Factory.insert(:shoutout, %{project: p})
      conn = login_user(conn, p.user)
      {:ok, view, _html} = live(conn, Routes.project_show_path(conn, :show, p.owner, p.name))

      assert view |> element(".relative:first-of-type") |> render() =~ s2.text
      refute view |> render() =~ s1.text
      element(view, "button", "Show 1 flagged shoutout") |> render_click()
      render(view)

      assert view |> render() =~ s1.text
      assert has_element?(view, "button", "Hide 1 flagged shoutout")
      assert has_element?(view, "button[title=\"Click to unflag this shoutout\"]")
    end

    test "clicking unflag shoutout updates the shoutout and removes the hide/show button", %{conn: conn} do
      p = Factory.insert(:project)
      s1 = Factory.insert(:shoutout, %{project: p, flagged: true})
      s2 = Factory.insert(:shoutout, %{project: p})
      conn = login_user(conn, p.user)
      {:ok, view, _html} = live(conn, Routes.project_show_path(conn, :show, p.owner, p.name))

      assert view |> element(".relative:first-of-type") |> render() =~ s2.text
      refute view |> render() =~ s1.text
      element(view, "button", "Show 1 flagged shoutout") |> render_click()
      element(view, "button[title=\"Click to unflag this shoutout\"]") |> render_click()
      render(view)

      refute Shoutouts.get_shoutout!(s1.id).flagged
      assert view |> element(".relative:first-of-type") |> render() =~ s2.text
      assert view |> element(".relative:last-of-type") |> render() =~ s1.text
      refute has_element?(view, "button", "Show 1 flagged shoutout")
    end
  end
end
