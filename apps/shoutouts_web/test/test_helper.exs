ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Shoutouts.Repo, :manual)
# Uncomment when running a subtest of tests on ShoutoutsWeb
# a full test run will have defined the mock in the shoutouts app
Mox.defmock(Shoutouts.MockProvider, for: Shoutouts.Provider)
Application.ensure_all_started(:mox)
