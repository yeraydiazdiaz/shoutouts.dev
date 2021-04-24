defmodule Shoutouts.Config do
  @doc """
  Reads configuration via Vapor.

  Callers will need to update their config as expected, usually in Application.
  """
  def load_config!() do
    # The file needs to be located at the root of the release
    config_path = "config.yaml"
    # Load configuration via Vapor
    bindings = [
      {:database_user, "DATABASE_USER"},
      {:database_pass, "DATABASE_PASS"},
      {:database_db, "DATABASE_DB"},
      {:database_hostname, "DATABASE_HOST"},
      {:github_token, "GITHUB_TOKEN"},
      {:github_client_id, "GITHUB_CLIENT_ID"},
      {:github_client_secret, "GITHUB_CLIENT_SECRET"},
      {:host, "HOST", default: "localhost"},
      {:port, "PORT", default: 443},
      {:secret_key_base, "SECRET_KEY_BASE"},
      {:sentry_dsn, "SENTRY_DSN"},
      {:dashboard_user, "DASHBOARD_USER"},
      {:dashboard_pass, "DASHBOARD_PASS"},
      {:sendgrid_api_key, "SENDGRID_API_KEY"}
    ]

    providers = [
      %Vapor.Provider.File{
        path: config_path,
        bindings: bindings
      }
      # TODO: Vapor will fail if any provider does not include all values.
      # So overriding via env vars is not possible. Adding required: false
      # will return `nil` and the precedence rules don't take that into
      # consideration ending with a config with nil values
      # %Vapor.Provider.Env{bindings: bindings}
    ]

    Vapor.load!(providers)
  end
end
