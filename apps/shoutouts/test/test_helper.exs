ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Shoutouts.Repo, :manual)
Mox.defmock(Shoutouts.MockProvider, for: Shoutouts.Provider)
Application.ensure_all_started(:mox)
