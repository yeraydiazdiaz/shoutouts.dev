defmodule ShoutoutsWeb.FaqController do
  use ShoutoutsWeb, :controller

  def show(conn, _params) do
    conn
    |> assign(:page_title, "FAQ")
    |> render("show.html")
  end
end
