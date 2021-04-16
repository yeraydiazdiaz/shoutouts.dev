defmodule ShoutoutsWeb.RegisterLiveTest do
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

  test "anonymous users are prompted to log in", %{conn: conn} do
    {:ok, view, html} = live(conn, Routes.project_register_path(conn, :index))
    assert html =~ "Register a project"
    assert html =~ "You must log in before you can register a project"
    assert has_element?(view, "a", "Log in with GitHub")
    refute has_element?(view, "form input")
  end

  test "renders form with input and buttons and register button is disabled", %{conn: conn} do
    user = Factory.insert(:user)
    conn = login_user(conn, user)

    {:ok, view, html} = live(conn, Routes.project_register_path(conn, :index))
    assert html =~ "Register a project"
    assert has_element?(view, "form input")
    assert has_element?(view, "form a", "Back")
    assert has_element?(view, "form input")
    assert element(view, "form button") |> render() =~ "disabled"
  end

  test "renders form with preloaded input from query arg", %{conn: conn} do
    user = Factory.insert(:user)
    conn = login_user(conn, user)

    {:ok, view, html} = live(conn, Routes.project_register_path(conn, :index, q: "foobar"))
    assert html =~ "Register a project"
    assert element(view, "form input[type='text']") |> render() =~ "foobar"
    assert has_element?(view, "form button", "Register project")
    assert has_element?(view, "form a", "Back")
  end

  describe "validate" do
    test "input with missing /", %{conn: conn} do
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

    test "GitHub URLs must exist in the provider", %{conn: conn} do
      Shoutouts.MockProvider
      |> expect(:client, fn -> Tesla.Client end)

      Shoutouts.MockProvider
      |> expect(:project_info, fn _client, _owner, _name ->
        {:ok, :no_such_repo}
      end)

      user = Factory.insert(:user)
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, Routes.project_register_path(conn, :index))

      assert view
             |> render_change(:validate, %{
               "registration" => %{"url_or_owner_name" => "https://github.com/foo/bar"}
             }) =~
               "The project does not exist or is not public, please check the URL for typos"
    end

    test "owner/name must exist in the provider", %{conn: conn} do
      Shoutouts.MockProvider
      |> expect(:client, fn -> Tesla.Client end)

      Shoutouts.MockProvider
      |> expect(:project_info, fn _client, _owner, _name ->
        {:ok, :no_such_repo}
      end)

      user = Factory.insert(:user)
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, Routes.project_register_path(conn, :index))

      assert view
             |> render_change(:validate, %{
               "registration" => %{"url_or_owner_name" => "foo/bar"}
             }) =~
               "The project does not exist or is not public, please check the URL for typos"
    end

    test "provider errors invalidate changeset", %{conn: conn} do
      Shoutouts.MockProvider
      |> expect(:client, fn -> Tesla.Client end)

      Shoutouts.MockProvider
      |> expect(:project_info, fn _client, _owner, _name ->
        {:error, %Tesla.Env{status: 500}}
      end)

      user = Factory.insert(:user)
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, Routes.project_register_path(conn, :index))

      assert view
             |> render_change(:validate, %{
               "registration" => %{"url_or_owner_name" => "foo/bar"}
             }) =~
               "There was an error trying to validate the project, please try again later"
    end

    test "projects must not already been registered", %{conn: conn} do
      project = Factory.insert(:project)
      user = Factory.insert(:user)
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, Routes.project_register_path(conn, :index))

      assert view
             |> render_change(:validate, %{
               "registration" => %{"url_or_owner_name" => "#{project.owner}/#{project.name}"}
             }) =~
               "The project has already been registered"
    end

    test "the user must not be an owner of the project", %{conn: conn} do
      project = Factory.insert(:project)
      user = Factory.insert(:user)
      conn = login_user(conn, user)

      Shoutouts.MockProvider
      |> expect(:client, fn -> Tesla.Client end)

      Shoutouts.MockProvider
      |> expect(:user_repositories, fn _client, _login ->
        {:ok, []}
      end)

      IO.inspect("Test calling live")
      {:ok, view, _html} = live(conn, Routes.project_register_path(conn, :index))

      assert view
             |> render_change(:validate, %{
               "registration" => %{"url_or_owner_name" => "#{project.owner}/#{project.name}"}
             }) =~
               "The project has already been registered"
    end

    test "valid inputs don't show errors and activate register button", %{conn: conn} do
      project = Factory.provider_project_factory(owner: "registered", name: "project")

      Shoutouts.MockProvider
      |> expect(:client, fn -> Tesla.Client end)

      Shoutouts.MockProvider
      |> expect(:project_info, fn _client, _owner, _name ->
        {:ok, project}
      end)

      user = Factory.insert(:user)
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, Routes.project_register_path(conn, :index))

      refute render_change(view, :validate, %{
               "registration" => %{"url_or_owner_name" => "#{project.owner}/#{project.name}"}
             }) =~ "text-alert"
    end
  end

  describe "register" do
    test "valid input registers project", %{conn: conn} do
      project = Factory.provider_project_factory(owner: "registered", name: "project")

      Shoutouts.MockProvider
      |> expect(:client, fn -> Tesla.Client end)

      Shoutouts.MockProvider
      |> expect(:project_info, fn _client, _owner, _name ->
        {:ok, project}
      end)

      user = Factory.insert(:user)
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, Routes.project_register_path(conn, :index))

      render_change(view, :register, %{
        "registration" => %{"url_or_owner_name" => "#{project.owner}/#{project.name}"}
      })

      flash =
        assert_redirected(
          view,
          Routes.project_show_path(conn, :add, project.owner, project.name)
        )

      assert flash["info"] == "Project registered correctly"
    end
  end
end
