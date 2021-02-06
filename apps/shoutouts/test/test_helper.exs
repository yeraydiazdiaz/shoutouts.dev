ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Shoutouts.Repo, :manual)
Mox.defmock(Shoutouts.MockProviderApp, for: Shoutouts.ProviderApp)
Application.ensure_all_started(:mox)
