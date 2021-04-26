defmodule ShoutoutsWeb.UserLiveTest do
  use ShoutoutsWeb.ConnCase

  import Mox
  setup :verify_on_exit!

  import Phoenix.LiveViewTest

  alias Shoutouts.Accounts
  alias Accounts.User
  alias Shoutouts.Factory
  alias Shoutouts.Projects
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

  describe ":show" do
    test "requires logged in user", %{conn: conn} do
      assert {:error, {:redirect, redirect}} = live(conn, Routes.user_index_path(conn, :show))
      assert redirect.to == "/"
    end

    test "renders account settings", %{conn: conn} do
      project = Factory.insert(:project)
      conn = login_user(conn, project.user)
      assert {:ok, view, html} = live(conn, Routes.user_index_path(conn, :show))

      assert html =~ project.user.name
      assert view |> element("#account-settings-form_name") |> render() =~ project.user.name
      assert view |> element("#account-settings-form_signature")
      options = view |> element("#account-settings-form_notify_when") |> render()
      assert options =~ "Disabled"
      assert options =~ "Weekly"
    end

    test "submitting changes updates user", %{conn: conn} do
      project = Factory.insert(:project)
      conn = login_user(conn, project.user)
      assert {:ok, view, _html} = live(conn, Routes.user_index_path(conn, :show))

      view |> form("#account-settings-form", %{"user" => %{signature: "New signature", notify_when: "disabled"}}) |> render_submit()

      user = Accounts.get_user(project.user.id)
      assert user.signature == "New signature"
      assert user.notify_when == :disabled
    end
  end

  describe ":add" do
    test "requires logged in user", %{conn: conn} do
      assert {:error, {:redirect, redirect}} = live(conn, Routes.user_index_path(conn, :add))
      assert redirect.to == "/"
    end

    test "renders user's repos checkboxes and an add projects button", %{conn: conn} do
      setup_mock(["owner/project1", "owner/project2"])
      project = Factory.insert(:project)
      conn = login_user(conn, project.user)
      assert {:ok, view, _html} = live(conn, Routes.user_index_path(conn, :add))
      assert view |> has_element?("label", "owner/project1")
      assert view |> has_element?("label", "owner/project2")
      assert view |> has_element?("button", "Add projects")
      assert view |> has_element?("a", "Back")
    end

    test "renders already registered projects as links to their pages", %{conn: conn} do
      setup_mock(["owner/project1", "owner/project2"])
      project = Factory.insert(:project, owner: "owner", name: "project1")
      conn = login_user(conn, project.user)
      assert {:ok, view, html} = live(conn, Routes.user_index_path(conn, :add))
      refute view |> element("input[type=\"checkbox\"]") |> render() =~ "owner/project1"
      assert view |> element("input[type=\"checkbox\"]") |> render() =~ "owner/project2"
      assert html =~ Routes.project_show_path(conn, :show, project.owner, project.name)
    end

    test "renders unclaimed registered projects as checkboxes", %{conn: conn} do
      setup_mock(["owner/project1", "owner/unclaimed"])
      owner = Factory.insert(:user)
      Factory.insert(:project, owner: "owner", name: "unclaimed", user: nil)
      conn = login_user(conn, owner)
      assert {:ok, view, _html} = live(conn, Routes.user_index_path(conn, :add))
      assert view |> has_element?("label", "owner/project1")
      assert view |> has_element?("label", "owner/unclaimed")
    end

    test "submitting repos add projects", %{conn: conn} do
      Shoutouts.MockProvider
      |> expect(:client, 3, fn -> Tesla.Client end)

      Shoutouts.MockProvider
      |> expect(:user_repositories, 2, fn _client, _login ->
        {:ok, ["owner/project1", "owner/project2"]}
      end)

      Shoutouts.MockProvider
      |> expect(:project_info, fn _client, _owner, _name ->
        {:ok, Factory.provider_project_factory(owner: "owner", name: "project1")}
      end)

      project = Factory.insert(:project)
      conn = login_user(conn, project.user)
      {:ok, view, _html} = live(conn, Routes.user_index_path(conn, :add))
      view |> form("#add", %{"repos[owner/project1]" => ""}) |> render_submit()
      flash = assert_redirect(view, Routes.user_index_path(conn, :projects))
      assert flash["info"] == "1 project(s) added successfully"
      assert Projects.project_exists?(project.owner, project.name)
    end

    test "claiming repos adds user ID to them", %{conn: conn} do
      Shoutouts.MockProvider
      |> expect(:client, 2, fn -> Tesla.Client end)

      Shoutouts.MockProvider
      |> expect(:user_repositories, 2, fn _client, _login ->
        {:ok, ["owner/unclaimed1", "owner/unclaimed2"]}
      end)

      owner = Factory.insert(:user)
      Factory.insert(:project, owner: "owner", name: "unclaimed1", user: nil)
      project = Factory.insert(:project, owner: "owner", name: "unclaimed2", user: nil)
      conn = login_user(conn, owner)
      {:ok, view, _html} = live(conn, Routes.user_index_path(conn, :add))
      view |> form("#claim", %{"projects[owner/unclaimed2]" => ""}) |> render_submit()
      refute view |> has_element?("label", "owner/unclaimed2")
      assert view |> render() =~ "1 project(s) claimed successfully"
      assert view |> render() =~ Routes.project_show_path(conn, :show, project.owner, project.name)
      assert Projects.get_project_by_owner_and_name!(project.owner, project.name).user_id == owner.id
    end
  end
end
