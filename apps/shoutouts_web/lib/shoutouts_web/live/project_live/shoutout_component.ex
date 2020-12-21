defmodule ShoutoutsWeb.ProjectLive.ShoutoutComponent do
  use ShoutoutsWeb, :live_component

  @impl true
  def handle_event("pin", _params, %{assigns: %{shoutout: shoutout}} = socket) do
    send(self(), {:pin_shoutout, shoutout})
    {:noreply, assign(socket, :shoutout, shoutout)}
  end

  @impl true
  def handle_event("unpin", _params, %{assigns: %{shoutout: shoutout}} = socket) do
    send(self(), {:unpin_shoutout, shoutout})
    {:noreply, assign(socket, :shoutout, shoutout)}
  end

  @impl true
  def handle_event("flag", _params, %{assigns: %{shoutout: shoutout}} = socket) do
    send(self(), {:flag_shoutout, shoutout})
    {:noreply, socket}
  end

  @impl true
  def handle_event("unflag", _params, %{assigns: %{shoutout: shoutout}} = socket) do
    send(self(), {:unflag_shoutout, shoutout})
    {:noreply, socket}
  end
end
