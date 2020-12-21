defmodule ShoutoutsWeb.IndexLive.Show do
  use ShoutoutsWeb, :live_view
  alias Shoutouts.Accounts
  alias Shoutouts.Shoutouts

  require Logger

  @doc """
  Home page.
  """
  def mount(_params, session, socket) do
    current_user_id = Map.get(session, "current_user_id")

    user =
      if current_user_id,
        do: Accounts.get_user!(current_user_id),
        else: nil

    {:ok,
     socket
     |> assign(:badge, Shoutouts.render_badge(13, 1.5))
     |> assign(:current_user, user)}
  end
end
