defmodule Shoutouts.MixProject do
  use Mix.Project

  def project do
    [
      app: :shoutouts,
      version: "22.1.1",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Shoutouts.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:ecto_sql, "~> 3.5"},
      {:postgrex, ">= 0.0.0"},
      {:jason, "~> 1.0"},
      {:ex_machina, "~> 2.4"},
      {:tesla, "~> 1.4.1"},
      {:hackney, "~> 1.17.3"},
      {:uuid, "~> 1.1"},
      {:vapor, "~> 0.10"},
      {:distillery, "~> 2.0"},
      # might fit better on _web but it depends on jason
      {:exmoji, "~> 0.3.0"},
      {:appsignal, "~> 2.0"},
      {:quantum, "~> 3.0"},
      {:mox, "~> 1.0", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
