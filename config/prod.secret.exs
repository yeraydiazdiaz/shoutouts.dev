# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
use Mix.Config

config :appsignal, :config,
  otp_app: :shoutouts,
  name: "shoutouts.dev",
  push_api_key: System.get_env("APPSIGNAL_PUSH_API_KEY"),
  env: Mix.env,
  active: true

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :shoutouts_web, ShoutoutsWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
