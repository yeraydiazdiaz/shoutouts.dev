defmodule ShoutoutsWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    Shoutouts.Config.load_config!()
    |> apply_config

    # List all child processes to be supervised
    children = [
      # Start the Telemetry supervisor
      ShoutoutsWeb.Telemetry,
      # Starts a worker by calling: ShoutoutsWeb.Worker.start_link(arg)
      # {ShoutoutsWeb.Worker, arg},
      {Phoenix.PubSub, [name: ShoutoutsWeb.PubSub, adapter: Phoenix.PubSub.PG2]},
      # Start the endpoint when the application starts
      ShoutoutsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ShoutoutsWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ShoutoutsWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp apply_config(config) do
    # Note changes to the endpoint's config are done in `init`
    Application.put_env(
      :ueberauth,
      Ueberauth.Strategy.Github.OAuth,
      client_id: config.github_client_id,
      client_secret: config.github_client_secret
    )

    Application.put_env(:sentry, :dsn, config.sentry_dsn)

    Application.put_env(:shoutouts_web, :dashboard_auth,
      username: config.dashboard_user,
      password: config.dashboard_pass
    )

    mailer_opts = Application.get_env(:shoutouts_web, ShoutoutsWeb.Email.Mailer)

    Application.put_env(
      :shoutouts_web,
      ShoutoutsWeb.Email.Mailer,
      mailer_opts ++ [api_key: config.sendgrid_api_key]
    )
  end
end
