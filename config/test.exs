use Mix.Config

config :shoutouts, :env, :test

# Configure your database
config :shoutouts, Shoutouts.Repo,
  username: "postgres",
  password: "postgres",
  database: "shoutouts_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :shoutouts, :github_token, "1234"

config :shoutouts, :default_provider, Shoutouts.MockProvider

# Configure the Tesla Mock adapter in tests
config :tesla, adapter: Tesla.Mock

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :shoutouts_web, ShoutoutsWeb.Endpoint,
  http: [port: 4002],
  server: false

config :shoutouts_web, ShoutoutsWeb.Email.Mailer, adapter: Bamboo.TestAdapter

# Print only warnings and errors during test
config :logger, level: :warn

config :appsignal, :config, active: false
