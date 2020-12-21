defmodule ShoutoutsWeb.SearchLive.SearchComponent do
  @moduledoc """
  Live component showing results.
  """
  use ShoutoutsWeb, :live_component
  alias Shoutouts.Projects

  require Logger

  def mount(socket) do
    socket =
      socket
      |> assign(:terms, "")
      |> assign(:results, [])

    {:ok, socket}
  end

  def update(%{terms: ""}, socket) do
    socket =
      socket
      |> assign(:terms, "")
      |> assign(:results, [])

    {:ok, socket}
  end

  def update(%{terms: terms}, socket) do
    socket =
      socket
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
