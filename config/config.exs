# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of Mix.Config.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
use Mix.Config

# Configure Mix tasks and generators
config :shoutouts,
  ecto_repos: [Shoutouts.Repo],
  env: Mix.env()

config :shoutouts_web,
  ecto_repos: [Shoutouts.Repo],
  generators: [context_app: :shoutouts]

# Configures the endpoint
config :shoutouts_web, ShoutoutsWeb.Endpoint,
  pubsub_server: ShoutoutsWeb.PubSub,
  render_errors: [view: ShoutoutsWeb.ErrorView, accepts: ~w(html json)],
  live_view: [signing_salt: "Fj7EyCQMfehidQBD"],
  signing_salt: "Bgpmwm3j"

config :logger,
  backends: [:console, Sentry.LoggerBackend],
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :tesla, adapter: Tesla.Adapter.Hackney

config :ueberauth, Ueberauth,
  json_library: Jason,
  providers: [
    github:
      {Ueberauth.Strategy.Github,
       [
         default_scope: "user,public_repo,notifications",
         allow_private_emails: true
       ]}
  ]

config :ueberauth, Ueberauth.Strategy.Github.OAuth, []

config :sentry,
  environment_name: Mix.env(),
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  tags: %{
    env:
      case Mix.env() do
        :dev -> "development"
        :prod -> "production"
        _ -> "unknown"
      end
  },
  # add :dev for testing
  included_environments: [:prod, :dev]

config :logger, Sentry.LoggerBackend, capture_log_messages: true

config :appsignal, :config,
  otp_app: :shoutouts,
  name: "shoutouts.dev",
  push_api_key: System.get_env("APPSIGNAL_PUSH_API_KEY"),
  env: Mix.env,
  active: false

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
