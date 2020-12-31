defmodule ShoutoutsWeb.Endpoint do
  use Sentry.PlugCapture
  use Phoenix.Endpoint, otp_app: :shoutouts_web

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_shoutouts_web_key",
    signed: true,
    signing_salt: "Bgpmwm3j",
    secure: Mix.env() == :prod,
    same_site: "lax",
    http_only: true,
    path: "/"
  ]

  socket "/socket", ShoutoutsWeb.UserSocket,
    websocket: true,
    longpoll: false

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :shoutouts_web,
    gzip: Mix.env() == :prod,
    only: ~w(css fonts images js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "Bgpmwm3j"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug PlugContentSecurityPolicy

  plug Sentry.PlugContext

  plug ShoutoutsWeb.Router

  def init(:supervisor, config) do
    vapor_config = Shoutouts.Config.load_config!()

    # Since we're deploying behind a proxy we want to set the URL to be
    # https://domain, but still start cowboy on a specific port that the proxy
    # will point to. In dev, however, we use the same port throughout and have
    # the generated URLs point to the local server
    {url_config, cowboy_port} =
      case vapor_config.port do
        443 -> {[host: vapor_config.host, scheme: "https", port: 443], 4000}
        port -> {[host: vapor_config.host, port: vapor_config.port], port}
      end

    new_config =
      Keyword.merge(
        config,
        url: url_config,
        http: [port: cowboy_port],
        secret_key_base: vapor_config.secret_key_base
      )

    {:ok, new_config}
  end
end
