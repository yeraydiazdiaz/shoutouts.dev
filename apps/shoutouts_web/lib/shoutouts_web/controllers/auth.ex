defmodule ShoutoutsWeb.Auth do
  @moduledoc """
  Authentication plug.

  Upon logging in the a :current_user is added to the conenction's assigns
  and a cookie with :current_user_id.
  """
  import Plug.Conn

  def init(opts), do: opts

  @doc """
  If a user already has been set in the connection do nothing.
  """
  def call(%{current_user: _} = conn) do
    conn
  end

  @doc """
  Sets the current_user from the current_user_id in the session if present.

  If not present, current_user_id is nil.
  If present and invalid, logout.
  """
  def call(conn, _opts) do
    # potentially nil
    current_user_id = get_session(conn, :current_user_id)
    conn = assign(conn, :current_user_id, current_user_id)

    if current_user_id do
      get_user_if_exists(conn, current_user_id)
    else
      conn
    end
  end

  defp get_user_if_exists(conn, user_id) do
    case Shoutouts.Accounts.get_user(user_id) do
      nil -> logout(conn)
      user -> assign(conn, :current_user, user)
    end
  end

  @doc """
  Logs a user in.

  Set assign conn.current_user and set current_user_id in session.
  """
  def login(conn, user) do
    conn
    # set the user in assigns
    |> assign(:current_user, user)
    # put the user ID in the session
    |> put_session(:current_user_id, user.id)
    # ensure the session is renewed with a different identifier
    |> configure_session(renew: true)
  end

  @doc """
  Log a user out

  Unset assign conn.current_user and current_user_id from session.
  """
  def logout(conn) do
    # Dropping the whole session will remove flash messages
    # configure_session(conn, drop: true)  # drops the whole session
    delete_session(conn, :current_user_id)
  end
end
