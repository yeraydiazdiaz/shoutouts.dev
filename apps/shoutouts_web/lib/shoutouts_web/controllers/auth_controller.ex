defmodule ShoutoutsWeb.AuthController do
  @moduledoc """
  Auth controller based on Ueberauth and Auth module.
  """
  require Logger
  use ShoutoutsWeb, :controller
  alias Shoutouts.Accounts
  alias ShoutoutsWeb.Router

  @doc """
  OAuth request, overridden to enable redirecting after authentication result.

  To be able to add the redirection URL to the session we had to override this
  method and manually call Ueberauth with the appropriate provider config.

  The redirection URL is picked from the referer of the auth request, i.e.
  the user is redirected to the page they were in.

  Note the redirect URL is set on the GitHub app configuration, so when testing
  on a different env, e.g. VirtualBox, logging in will not work unless changed
  in the GitHub app.
  """
  def request(
        %{assigns: %{current_user_id: nil}} = conn,
        %{"provider" => provider_name} = _params
      ) do
    conn
    |> put_session(:redirect_to, redirect_target(conn))
    |> Ueberauth.run_request(provider_name, get_provider_config())
  end

  @doc """
  OAuth successful callback.
  """
  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    Logger.debug("Successful OAuth")
    {:ok, user} = Accounts.get_or_create_user_from_auth(auth)

    conn
    |> ShoutoutsWeb.Auth.login(user)
    |> put_flash(:info, "Successfully authenticated.")
    |> redirect(to: redirect_to(conn))
  end

  # OAuth failure callback, can't do a lot just log and flash.
  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    Logger.error("Authentication failure")

    conn
    |> put_flash(
      :error,
      "Sorry, something went wrong with the authentication. We'll look into it but please try again later."
    )
    |> redirect(to: redirect_to(conn))
  end

  # OAuth callback with no assigns, i.e. not yet processed by Ueberauth.
  # Needed since we're overriding behaviour included in `plug Ueberauth`.
  def callback(conn, %{"provider" => provider} = params) do
    Logger.debug("Callback with no assigns")

    Ueberauth.run_callback(conn, provider, get_provider_config())
    |> callback(params)
  end

  @doc """
  Logout handler.
  """
  def delete(conn, _params) do
    conn
    |> ShoutoutsWeb.Auth.logout()
    |> put_flash(:info, "You have logged out successfully")
    |> redirect(to: "/")
  end

  def impersonate(%{assigns: %{current_user: current_user}} = conn, %{"username" => username}) do
    if current_user.role != :admin do
      raise ShoutoutsWeb.NotFoundError, "Not found"
    end

    case Accounts.get_user_by_username(username) do
      nil ->
        raise ShoutoutsWeb.NotFoundError, "Not found"

      user ->
        conn
        |> ShoutoutsWeb.Auth.login(user)
        |> redirect(to: "/")
    end
  end

  def redirect_target(conn) do
    case fetch_query_params(conn).query_params do
      %{"next" => next_path} -> next_path
      _ -> referer_from_headers(conn)
    end
  end

  defp referer_from_headers(conn) do
    case Enum.find(conn.req_headers, fn {header, _value} -> header == "referer" end) do
      {"referer", referer} -> referer
      nil -> nil
    end
  end

  defp redirect_to(conn) do
    default_path = Router.Helpers.user_index_path(conn, :projects)

    case get_session(conn, :redirect_to) do
      nil ->
        default_path

      r ->
        delete_session(conn, :redirect_to)
        parsed = URI.parse(r)
        path = "#{parsed.path}?#{parsed.query}"
        if path == "/", do: default_path, else: path
    end
  end

  defp get_provider_config do
    # I know... but at least it's not hardcoded
    [_, {:providers, [{:github, config}]}] = Application.get_env(:ueberauth, Ueberauth)
    config
  end
end
