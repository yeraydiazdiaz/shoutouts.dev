defmodule ShoutoutsWeb.UserLiveTest do
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

  describe ":show" do
    test "requires logged in user", %{conn: conn} do
      assert {:error, {:redirect, redirect}} = live(conn, Routes.user_index_path(conn, :show))
      assert redirect.to == "/"
    end

    test ":show renders account settings", %{conn: conn} do
      project = Factory.insert(:project)
      conn = login_user(conn, project.user)
      assert {:ok, _view, html} = live(conn, Routes.user_index_path(conn, :show))

      assert html =~ project.user.name
    end
  end

  describe ":add" do
    test "requires logged in user", %{conn: conn} do
      assert {:error, {:redirect, redirect}} = live(conn, Routes.user_index_path(conn, :add))
      assert redirect.to == "/"
    end

    test "renders user's repos checkboxes and an add projects button ", %{conn: conn} do
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
  end
end
