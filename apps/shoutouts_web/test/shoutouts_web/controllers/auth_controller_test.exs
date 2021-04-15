defmodule ShoutoutsWeb.AuthControllerTest do
  use ShoutoutsWeb.ConnCase

  alias Shoutouts.Factory
  alias ShoutoutsWeb.AuthController

  @ueberauth_success %Ueberauth.Auth{
    info: %Ueberauth.Auth.Info{
      email: "user@example.org",
      name: "John Doe",
      nickname: "johndoe",
      image: "https://example.org/avatar/"
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
    strategy: Ueberauth.Strategy.Github
  }

  describe "GET /auth/github/callback" do
    test "assigns current_user and sets session current_user_id", %{conn: conn} do
      conn = assign(conn, :ueberauth_auth, @ueberauth_success)
      conn = get(conn, Routes.auth_path(conn, :callback, :github))
      assert redirected_to(conn) == "/account/projects"
      assert conn.assigns.current_user.username == "johndoe"
      assert conn.assigns.current_user.name == "John Doe"
      assert conn.assigns.current_user.email == "user@example.org"
      assert conn.assigns.current_user.provider == :github
      assert conn.assigns.current_user.provider_id == 1234
      assert get_session(conn, :current_user_id) != nil

      conn = get(conn, "/")
      assert html_response(conn, 200) =~ "Successfully authenticated"
    end

    test "OAuth failure", %{conn: conn} do
      conn = assign(conn, :ueberauth_failure, %{})
      conn = get(conn, Routes.auth_path(conn, :callback, :github))
      assert redirected_to(conn) == "/account/projects"

      conn = get(conn, "/")
      assert html_response(conn, 200) =~ "Sorry, something went wrong with the authentication."
    end

    test "redirects to session redirect_to", %{conn: conn} do
      conn = conn
      |> assign(:ueberauth_auth, @ueberauth_success)
      |> init_test_session(%{redirect_to: "/some/path?q=foobar"})
      conn = get(conn, Routes.auth_path(conn, :callback, :github))
      assert redirected_to(conn) == "/some/path?q=foobar"
    end

    test "redirects to session redirect_to using only the path or the URL", %{conn: conn} do
      conn = conn
      |> assign(:ueberauth_auth, @ueberauth_success)
      |> init_test_session(%{redirect_to: "http://localhost:4000/some/path?q=foobar"})
      conn = get(conn, Routes.auth_path(conn, :callback, :github))
      assert redirected_to(conn) == "/some/path?q=foobar"
    end
  end

  test "GET /auth/logout", %{conn: conn} do
    conn = assign(conn, :current_user, Factory.insert(:user))
    conn = get(conn, Routes.auth_path(conn, :delete))
    assert redirected_to(conn) == "/"
    assert :current_user not in conn.assigns
    assert get_session(conn, :current_user_id) == nil

    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "You have logged out"
  end

  describe "redirect_target" do
    test "returns nil by default", %{conn: conn} do
      assert AuthController.redirect_target(conn) == nil
    end

    test "returns referer from HTTP request headers" do
      conn = %Plug.Conn{req_headers: [{"referer", "/some/referer"}]}
      assert AuthController.redirect_target(conn) == "/some/referer"
    end

    test "returns value of 'next' query arg if present" do
      conn = %Plug.Conn{query_string: "next=%2Fsome%2fpath"}
      assert AuthController.redirect_target(conn) == "/some/path"
    end
  end
end
