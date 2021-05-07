defmodule ShoutoutsWeb.SearchLive.Show do
  @moduledoc """
  Search LiveView. The `q` query parameter drives the search, if it is missing
  we display a summary of the top projects by language.

  The SearchLive.SearchComponent displays the form and the results.
  """
  use ShoutoutsWeb, :live_view
  alias Shoutouts.Projects

  require Logger

  def mount(params, session, socket) do
    summary = Projects.summary_by_languages(6, 5)
    {terms, results} = parse_params(params)

    {:ok,
     socket
     |> assign(:page_title, "Search")
     |> assign(:current_user_id, Map.get(session, "current_user_id"))
     |> assign(:terms, terms)
     |> assign(:results, results)
     |> assign(:summary, summary)}
  end

  def handle_event("search", params, socket) do
    path = case params do
      %{"q" => ""} -> Routes.search_show_path(socket, :index)
      %{"q" => terms} -> Routes.search_show_path(socket, :index, q: terms)
    end
    {:noreply, push_patch(socket, to: path)}
  end

  def handle_params(params, _uri, socket) do
    {terms, results} = parse_params(params)

    {:noreply,
     socket
     |> assign(:terms, terms)
     |> assign(:results, results)}
  end

  defp parse_params(params) do
    case params do
      %{"q" => ""} -> {"", []}
      %{"q" => terms} -> {terms, do_search(terms)}
      _ -> {"", []}
    end
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
