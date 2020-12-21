defmodule Shoutouts.Repo do
  use Ecto.Repo,
    otp_app: :shoutouts,
    adapter: Ecto.Adapters.Postgres

  @doc """
  Override initialization to update configuration from Vapor on migrations.

  https://github.com/keathley/vapor/issues/97
  """
  def init(_context, config) do
    case Keyword.has_key?(config, :database) do
      true ->
        {:ok, config}

      false ->
        IO.puts("Loading config from Vapor")
        vapor_config = load_vapor_config()
        {:ok, Keyword.merge(config, vapor_config)}
    end
  end

  defp load_vapor_config() do
    config = Shoutouts.Config.load_config!()

    opts = [
      username: config.database_user,
      password: config.database_pass,
      database: config.database_db,
      hostname: config.database_hostname,
      show_sensitive_data_on_connection_error: true,
      pool_size: 10
    ]

    Application.put_env(:shoutouts, Shoutouts.Repo, opts)
    # Return the keyword options for the repo
    opts
  end
end
