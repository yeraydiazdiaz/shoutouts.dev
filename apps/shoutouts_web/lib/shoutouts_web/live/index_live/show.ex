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

    shoutouts = Shoutouts.shoutouts_for_top_projects()

    {:ok,
     socket
     |> assign(:badge, Shoutouts.render_badge(13, 1.5))
     |> assign(:current_user, user)
     |> assign(:shoutouts, shoutouts)
     |> assign(:shoutout, List.first(shoutouts))}
  end
end
