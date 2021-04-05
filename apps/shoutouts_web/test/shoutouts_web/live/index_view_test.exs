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

end
