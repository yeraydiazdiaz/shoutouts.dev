defmodule ShoutoutsWeb.SponsorsController do
  use ShoutoutsWeb, :controller

  def show(conn, _params) do
    conn
    |> assign(:page_title, "Sponsors")
    |> render("show.html")
  end
end
