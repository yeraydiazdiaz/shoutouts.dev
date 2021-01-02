defmodule ShoutoutsWeb.UserLiveTest do
  use ShoutoutsWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Shoutouts.Accounts.User
  alias Shoutouts.Factory

  defp auth_for_user(user) do
    %Ueberauth.Auth{
      info: %Ueberauth.Auth.Info{
        email: user.email,
        name: user.name,
        nickname: user.username,
        image: "https://example.org/avatar/#{user.username}",
      },
      extra: %{
        raw_info: %{
          user: %{
            "created_at" => "2014-02-20T16:58:32Z"
          }
        }
      },
      provider: :github,
      uid: 1234,
      strategy: Ueberauth.Strategy.Github,
    }
  end

  defp login_user(conn, %User{} = user) do
    conn
      |> assign(:ueberauth_auth, auth_for_user(user))
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
