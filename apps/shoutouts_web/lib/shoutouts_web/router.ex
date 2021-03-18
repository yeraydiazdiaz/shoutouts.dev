defmodule ShoutoutsWeb.Router do
  use ShoutoutsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ShoutoutsWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug ShoutoutsWeb.Auth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ShoutoutsWeb do
    pipe_through :browser

    live "/", IndexLive.Show, :show
    live "/search", SearchLive.Show, :index
    live "/faq", FaqLive.Show, :index

    live "/account", UserLive.Index, :show
    live "/account/projects", UserLive.Index, :projects
    live "/account/projects/add", UserLive.Index, :add
    live "/account/projects/:id/edit", UserLive.Index, :edit_project
    live "/account/projects/:id/delete", UserLive.Index, :delete
    live "/account/shoutouts", UserLive.Index, :shoutouts

    live "/projects/:owner/:name", ProjectLive.Show, :show
    live "/projects/:owner/:name/add", ProjectLive.Show, :add
    get "/projects/:owner/:name/badge", ProjectController, :badge
  end

  scope "/auth", ShoutoutsWeb do
    pipe_through :browser

    get "/logout", AuthController, :delete
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback

    get "/admin/impersonate/:username", AuthController, :impersonate
  end

  # Other scopes may use custom stacks.
  # scope "/api", ShoutoutsWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  import Phoenix.LiveDashboard.Router

  if Mix.env() == :dev do
    pipeline :dashboard do
      plug :dashboard_auth
    end

    defp dashboard_auth(conn, _opts) do
      creds = Application.get_env(:shoutouts_web, :dashboard_auth)
      Plug.BasicAuth.basic_auth(conn, creds)
    end

    scope "/dashboard" do
      pipe_through(:browser)
      pipe_through(:dashboard)

      live_dashboard("/",
        metrics: ShoutoutsWeb.Telemetry,
        ecto_repos: [Shoutouts.Repo]
      )
    end
  end
end
