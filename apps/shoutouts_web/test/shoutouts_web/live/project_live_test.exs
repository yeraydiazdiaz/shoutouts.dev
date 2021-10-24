defmodule ShoutoutsWeb.ProjectLiveTest do
  use ShoutoutsWeb.ConnCase

  import Mox
  setup :verify_on_exit!

  import Phoenix.LiveViewTest

  alias Shoutouts.Accounts.User
  alias Shoutouts.Factory
  alias ShoutoutsWeb.TestHelpers

  def login_user(conn, %User{} = user) do
    conn
    |> assign(:ueberauth_auth, TestHelpers.auth_for_user(user))
    |> get(Routes.auth_path(conn, :callback, :github))
  end

  def setup_mock(user_repositories \\ []) do
    Shoutouts.MockProvider
    |> expect(:client, 2, fn -> Tesla.Client end)

    Shoutouts.MockProvider
    |> expect(:user_repositories, 2, fn _client, _login ->
      {:ok, user_repositories}
    end)
  end

  test "raises 404 if the project does not exist", %{conn: conn} do
    assert_raise ShoutoutsWeb.NotFoundError, fn ->
      get(conn, Routes.project_show_path(conn, :show, "doesnt", "exist"))
    end
  end

  test "returns 301 when requesting a project with an old owner/name", %{conn: conn} do
    p = Factory.insert(:project, previous_owner_names: ["me/old"])
    conn = get(conn, Routes.project_show_path(conn, :show, "me", "old"))
    assert conn.status == 301
    {_, location} = Enum.find(conn.resp_headers, fn {h, _} -> h == "location" end)
    assert location == Routes.project_show_path(conn, :show, p.owner, p.name)
  end

  test "renders project title, description, and no shoutouts copy", %{conn: conn} do
    p = Factory.insert(:project)
    {:ok, _view, html} = live(conn, Routes.project_show_path(conn, :show, p.owner, p.name))
    assert html =~ "#{p.owner}/#{p.name}"
    assert html =~ p.description
    assert html =~ p.primary_language
    assert html =~ "No shoutouts yet"
  end

  test "does not render primary language if nil", %{conn: conn} do
    p = Factory.insert(:project, primary_language: nil)
    {:ok, _view, html} = live(conn, Routes.project_show_path(conn, :show, p.owner, p.name))
    assert html =~ "#{p.owner}/#{p.name}"
    assert html =~ p.description
    refute html =~ "Written mostly in:"
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

  test "anonymous users are prompted to log in to leave a shoutout", %{conn: conn} do
    p = Factory.insert(:project)
    {:ok, view, _html} = live(conn, Routes.project_show_path(conn, :show, p.owner, p.name))

    assert element(view, "a", "Log in to leave a shoutout") |> render() =~
             Routes.auth_path(conn, :request, :github)
  end

  describe "logged in users" do
    test "are prompted to leave the first shoutout", %{conn: conn} do
      setup_mock()
      u = Factory.insert(:user)
      conn = login_user(conn, u)
      p = Factory.insert(:project)
      {:ok, view, _html} = live(conn, Routes.project_show_path(conn, :show, p.owner, p.name))

      assert element(view, "a", "Be the first!") |> render() =~
               Routes.project_show_path(conn, :add, p.owner, p.name)
    end

    test "are prompted to leave a shoutout", %{conn: conn} do
      setup_mock()
      p = Factory.insert(:project)
      Factory.insert(:shoutout, %{project: p})
      u = Factory.insert(:user)
      conn = login_user(conn, u)
      {:ok, view, _html} = live(conn, Routes.project_show_path(conn, :show, p.owner, p.name))

      assert element(view, "a", "Add your shoutout") |> render() =~
               Routes.project_show_path(conn, :add, p.owner, p.name)
    end

    test "that have already left a shoutout are not prompted to leave another, and a Twitter button is shown",
         %{conn: conn} do
      setup_mock()
      owner = Factory.insert(:user, %{name: "owner"})
      p = Factory.insert(:project, %{user: owner})
      s = Factory.insert(:shoutout, %{project: p})
      conn = login_user(conn, s.user)
      {:ok, view, html} = live(conn, Routes.project_show_path(conn, :show, p.owner, p.name))

      assert html =~ s.text
      assert html =~ s.user.name
      refute html =~ "Add your shoutout"
      twitter_button = element(view, "button[title=\"Share on Twitter\"]") |> render()

      assert twitter_button =~
               Plug.Conn.Query.encode(%{
                 text: "Shoutout to #{p.user.name}'s #{String.capitalize(p.name)}: #{s.text}"
               })
    end

    test "whose provider account is too young are not prompted to leave a shoutout",
         %{conn: conn} do
      setup_mock()
      owner = Factory.insert(:user, %{name: "owner"})
      p = Factory.insert(:project, %{user: owner})
      u = Factory.insert(:user, %{provider_joined_at: DateTime.utc_now()})
      conn = login_user(conn, u)
      {:ok, _view, html} = live(conn, Routes.project_show_path(conn, :show, p.owner, p.name))

      refute html =~ "Add your shoutout"

      assert html =~
               "Sorry, only users with a provider account older than 3 months are allowed to add shoutouts"
    end

    test "that have left a flagged shoutout on another of the user's projects are not prompted to leave another",
         %{conn: conn} do
      setup_mock()
      owner = Factory.insert(:user, %{name: "owner"})
      other_project = Factory.insert(:project, %{user: owner})
      p = Factory.insert(:project, %{user: owner})
      u = Factory.insert(:user)
      Factory.insert(:shoutout, %{project: other_project, user: u, flagged: true})
      conn = login_user(conn, u)
      {:ok, _view, html} = live(conn, Routes.project_show_path(conn, :show, p.owner, p.name))

      refute html =~ "Add your shoutout"

      assert html =~
               "The owner of this project has flagged a shoutout on another one of their projects"
    end

    test "that have left a flagged shoutouts on more than 2 other projects are not prompted to leave a shoutout",
         %{conn: conn} do
      setup_mock()
      u = Factory.insert(:user)
      # > @owner_flagged_threshold in show.ex
      1..3
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

    test "owners of unclaimed projects are prompted to register them in accounts settings", %{
      conn: conn
    } do
      owner = Factory.insert(:user, %{username: "owner"})
      p = Factory.insert(:project, user: nil)
      setup_mock(["#{p.owner}/#{p.name}"])
      Factory.insert(:shoutout, %{project: p})
      conn = login_user(conn, owner)
      {:ok, _view, html} = live(conn, Routes.project_show_path(conn, :show, p.owner, p.name))

      assert html =~ "Add your shoutout"
      assert html =~ "It looks like you are one of the owners of this project"
      assert html =~ Routes.user_index_path(conn, :add)
    end
  end

  describe "project owners" do
    test "pin, flag, and tweet buttons are rendered on each shoutout", %{conn: conn} do
      setup_mock()
      p = Factory.insert(:project)
      s = Factory.insert(:shoutout, %{project: p})
      conn = login_user(conn, p.user)
      {:ok, view, html} = live(conn, Routes.project_show_path(conn, :show, p.owner, p.name))

      refute html =~ "Add your shoutout"
      assert html =~ "We hope you enjoy the shoutouts for your project"
      assert has_element?(view, "button[title=\"Click to pin this shoutout\"]")
      assert has_element?(view, "button[title=\"Click to flag this shoutout\"]")
      twitter_button = element(view, "button[title=\"Share on Twitter\"]") |> render()

      assert twitter_button =~
               Plug.Conn.Query.encode(%{
                 text: "\"#{s.text}\" — #{s.user.name}"
               })
    end

    test "pinning a shoutout updates it and renders it at the top", %{conn: conn} do
      setup_mock()
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
      assert Shoutouts.Shoutouts.get_shoutout!(s1.id).pinned
      assert has_element?(view, "button[title=\"Click to unpin this shoutout\"]")
    end

    test "flagging a shoutout updates it and hides it behind a button", %{conn: conn} do
      setup_mock()
      p = Factory.insert(:project)
      s1 = Factory.insert(:shoutout, %{project: p})
      s2 = Factory.insert(:shoutout, %{project: p})
      conn = login_user(conn, p.user)
      {:ok, view, _html} = live(conn, Routes.project_show_path(conn, :show, p.owner, p.name))

      assert view |> element(".relative:first-of-type") |> render() =~ s2.text
      assert view |> element(".relative:last-of-type") |> render() =~ s1.text
      element(view, "##{s1.id} button[title=\"Click to flag this shoutout\"]") |> render_click()
      render(view)

      assert Shoutouts.Shoutouts.get_shoutout!(s1.id).flagged
      assert view |> element(".relative:first-of-type") |> render() =~ s2.text
      refute view |> render() =~ s1.text
      assert has_element?(view, "button", "Show 1 flagged shoutout")
    end

    test "clicking show flagged shoutouts shows flagged shoutouts", %{conn: conn} do
      setup_mock()
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

    test "clicking unflag shoutout updates the shoutout and removes the hide/show button", %{
      conn: conn
    } do
      setup_mock()
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

      refute Shoutouts.Shoutouts.get_shoutout!(s1.id).flagged
      assert view |> element(".relative:first-of-type") |> render() =~ s2.text
      assert view |> element(".relative:last-of-type") |> render() =~ s1.text
      refute has_element?(view, "button", "Show 1 flagged shoutout")
    end
  end
end
