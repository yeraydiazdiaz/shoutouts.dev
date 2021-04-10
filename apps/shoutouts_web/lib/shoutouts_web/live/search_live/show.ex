defmodule ShoutoutsWeb.SearchLive.Show do
  use ShoutoutsWeb, :live_view
  alias Shoutouts.Projects

  require Logger

  @doc """
  Query arg terms.
  """
  def mount(%{"q" => terms}, session, socket) do
    summary = Projects.summary_by_languages(6, 5)

    {:ok,
     socket
     |> assign(:current_user_id, Map.get(session, "current_user_id"))
     |> assign(:terms, terms)
     |> assign(:summary, summary)}
  end

  # No query arg entry point.
  def mount(_params, session, socket) do
    summary = Projects.summary_by_languages(6, 5)

    {:ok,
     socket
     |> assign(:current_user_id, Map.get(session, "current_user_id"))
     |> assign(:terms, "")
     |> assign(:summary, summary)}
  end

  # The event payload will usually be the event itself, except for forms.
  def handle_event("search", %{"q" => terms}, socket) do
    {:noreply,
     socket
     |> assign(:terms, terms)}
  end
end
