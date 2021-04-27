defmodule ShoutoutsWeb.SearchLive.SearchComponent do
  @moduledoc """
  Live component showing results.
  """
  use ShoutoutsWeb, :live_component
  alias Shoutouts.Projects

  require Logger

  def mount(socket) do
    {:ok,
     socket
     |> assign(:current_user_id, nil)
     |> assign(:terms, "")
     |> assign(:results, [])}
  end

  def update(%{terms: "", current_user_id: current_user_id} = _assigns, socket) do
    socket =
      socket
      |> assign(:current_user_id, current_user_id)
      |> assign(:terms, "")
      |> assign(:results, [])

    {:ok, socket}
  end

  def update(%{terms: terms, current_user_id: current_user_id}, socket) do
    socket =
      socket
      |> assign(:current_user_id, current_user_id)
      |> assign(:terms, terms)
      |> assign(:results, do_search(terms))

    {:ok, socket}
  end

  defp do_search(terms) do
    Logger.debug("Searching for `#{terms}`")
    terms = String.trim(terms)

    case Regex.match?(~r/^[\w\s\/-]{2,50}$/, terms) do
      true -> Projects.search(terms)
      false -> []
    end
  end
end
