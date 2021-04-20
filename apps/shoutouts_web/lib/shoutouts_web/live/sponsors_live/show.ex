defmodule ShoutoutsWeb.SponsorsLive.Show do
  use ShoutoutsWeb, :live_view

  require Logger

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Sponsors")}
  end
end
