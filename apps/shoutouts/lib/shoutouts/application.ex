defmodule Shoutouts.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    unless Application.get_env(:shoutouts, :env) == :test do
      Shoutouts.Config.load_config!()
      |> apply_config
    end

    children = [
      Shoutouts.ProcessRegistry,
      Shoutouts.Repo,
      Shoutouts.Scheduler
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Shoutouts.Supervisor)
  end

  defp apply_config(config) do
    Application.put_env(:shoutouts, Shoutouts.Repo,
      username: config.database_user,
      password: config.database_pass,
      database: config.database_db,
      hostname: config.database_hostname,
      show_sensitive_data_on_connection_error: true,
      pool_size: 10
    )

    Application.put_env(:shoutouts, :github_token, config.github_token)
  end
end
