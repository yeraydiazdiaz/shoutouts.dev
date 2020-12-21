defmodule ShoutoutsWeb.PageController do
  use ShoutoutsWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
