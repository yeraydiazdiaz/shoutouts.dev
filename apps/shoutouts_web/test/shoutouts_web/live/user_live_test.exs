defmodule ShoutoutsWeb.UserLiveTest do
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

  describe "UserLive.Index" do
    test "requires logged in user", %{conn: conn} do
      assert {:error, {:redirect, redirect}} = live(conn, Routes.user_index_path(conn, :show))
      assert redirect.to == "/"
    end

    test ":show renders account settings", %{conn: conn} do
      project = Factory.insert(:project)
      conn = login_user(conn, project.user)
      assert  {:ok, _view, html} = live(conn, Routes.user_index_path(conn, :show))

      assert html =~ project.user.name
    end
  end
end
