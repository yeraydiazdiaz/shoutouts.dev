defmodule ShoutoutsWeb.ErrorViewTest do
  use ShoutoutsWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 403.html" do
    assert render_to_string(ShoutoutsWeb.ErrorView, "403.html", []) =~ "Unauthorized"
  end

  test "renders 404.html" do
    assert render_to_string(ShoutoutsWeb.ErrorView, "404.html", []) =~ "Not found"
  end

  test "renders 500.html" do
    assert render_to_string(ShoutoutsWeb.ErrorView, "500.html", []) =~ "Oops, something's wrong"
  end
end
