defmodule ShoutoutsWeb.SearchLiveTest do
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

  test "anonymous users are prompted to log in", %{conn: conn} do
    {:ok, view, html} = live(conn, Routes.project_register_path(conn, :index))
    assert html =~ "Register a project"
    assert html =~ "You must log in before you can register a project"
    assert has_element?(view, "a", "Log in with GitHub")
    refute has_element?(view, "form input")
  end

  test "renders form with input and buttons", %{conn: conn} do
    user = Factory.insert(:user)
    conn = login_user(conn, user)

    {:ok, view, html} = live(conn, Routes.project_register_path(conn, :index))
    assert html =~ "Register a project"
    assert has_element?(view, "form input")
    assert has_element?(view, "form button", "Register project")
    assert has_element?(view, "form a", "Back")
  end

  describe "invalid inputs render an error" do
    test "missing /", %{conn: conn} do
      user = Factory.insert(:user)
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, Routes.project_register_path(conn, :index))

      assert view
             |> render_change(:validate, %{
               "registration" => %{"url_or_owner_name" => "not-valid"}
             }) =~
               "A GitHub project URL or owner/name is required"
    end

    test "invalid GitHub URL", %{conn: conn} do
      user = Factory.insert(:user)
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, Routes.project_register_path(conn, :index))

      assert view
             |> render_change(:validate, %{
               "registration" => %{"url_or_owner_name" => "https://not-github.com/foo/bar"}
             }) =~
               "A GitHub project URL or owner/name is required"
    end
  end

  # accepts GitHub URLs
  # accepts owner/name
end
