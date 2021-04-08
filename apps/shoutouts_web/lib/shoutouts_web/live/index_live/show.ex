defmodule ShoutoutsWeb.IndexLive.Show do
  use ShoutoutsWeb, :live_view
  alias Shoutouts.Accounts
  alias Shoutouts.Projects
  alias Shoutouts.Shoutouts

  require Logger

  @carrousel_timeout 3000

  @doc """
  Home page.
  """
  def mount(_params, session, socket) do
    current_user_id = Map.get(session, "current_user_id")

    user =
      if current_user_id,
        do: Accounts.get_user!(current_user_id),
        else: nil

    shoutouts =
      case Shoutouts.shoutouts_for_top_projects() do
        [] -> [default_shoutout()]
        stp -> stp
      end

    if connected?(socket) and shoutouts != [],
      do: Process.send_after(self(), :carrousel_timeout, @carrousel_timeout)

    {:ok,
     socket
     |> assign(:badge, Shoutouts.render_badge(13, 1.5))
     |> assign(:current_user, user)
     |> assign(:shoutouts, shoutouts)
     |> assign(:shoutout_idx, 0)
     |> assign(:should_switch, true)}
  end

  @doc """
  Handles the click on the carrousel buttons to switch the active shoutout.
  """
  def handle_event("carrousel_switch", %{"idx" => idx}, socket) do
    {next_idx, ""} = Integer.parse(idx)

    {:noreply,
     socket
     |> assign(:shoutout_idx, next_idx)
     |> assign(:should_switch, false)}
  end

  @doc """
  Handles the timeout on the carrousel to switch the active shoutout.

  If the user has previously clicked on a button we don't do anything, otherwise we switch.
  """
  def handle_info(:carrousel_timeout, %{assigns: %{should_switch: false}} = socket) do
    {:noreply, socket}
  end

  def handle_info(:carrousel_timeout, %{assigns: %{should_switch: true}} = socket) do
    Process.send_after(self(), :carrousel_timeout, @carrousel_timeout) 
    next_idx = rem(socket.assigns[:shoutout_idx] + 1, length(socket.assigns[:shoutouts]))
    {:noreply, assign(socket, :shoutout_idx, next_idx)}
  end

  defp default_shoutout() do
    %Shoutouts.Shoutout{
      text: "Your project is amazing!\nThanks for everything you do!",
      user: %Accounts.User{
        name: "Amy Grateful",
        signature: "Prolific Open Source contributor"
      },
      project: %Projects.Project{
        owner: "yeraydiazdiaz",
        name: "shoutouts.dev"
      }
    }
  end
end
