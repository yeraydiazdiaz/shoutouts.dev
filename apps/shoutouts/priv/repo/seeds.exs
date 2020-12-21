# Script for populating the database. You can run it as:
#
#     mix run apps/shoutouts/priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Shoutouts.Repo.insert!(%Shoutouts.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Shoutouts.Accounts
alias Shoutouts.Projects
alias Shoutouts.Shoutouts

users = [
  %{
    avatar_url: "https://avatars1.githubusercontent.com/u/6739793?v=4",
    email: "yeray@shoutouts.dev",
    name: "Yeray Diaz Diaz",
    provider_id: 6_739_793,
    provider_joined_at: ~U[2014-02-20 16:58:32Z],
    role: "admin",
    signature: "",
    username: "yeraydiazdiaz"
  },
  %{
    username: "johndoe",
    email: "test@example.org",
    name: "John Doe",
    avatar_url: "https://avatars2.githubusercontent.com/u/13053714",
    provider_id: 1234,
    provider_joined_at: ~U[2014-02-20T16:58:32Z]
  },
  %{
    username: "janedoe",
    email: "test@example.org",
    name: "Jane Doe",
    signature: "Prolific open source contributor",
    avatar_url: "https://avatars2.githubusercontent.com/u/1312925",
    provider_id: 9012,
    provider_joined_at: ~U[2016-02-20T16:58:32Z]
  },
  %{
    username: "youngone",
    email: "test@example.org",
    name: "Young One",
    avatar_url: "https://avatars0.githubusercontent.com/u/42996147",
    provider_id: 5678,
    provider_joined_at: ~U[2020-02-20T16:58:32Z]
  },
  %{
    username: "naughtyone",
    email: "naughty@example.org",
    name: "Naughty One",
    signature: "Just some random troll",
    avatar_url: "https://avatars2.githubusercontent.com/u/1312925",
    provider_id: 9105,
    provider_joined_at: ~U[2016-02-20T16:58:32Z]
  }
]

users
|> Enum.map(fn u -> {:ok, _} = Accounts.create_user(u) end)

admin = Accounts.get_user_by_username("yeraydiazdiaz")

project_attrs = %{
  description: "Open Source is hard. Show your gratitude",
  forks: 0,
  homepage_url: "https://github.com/yeraydiazdiaz/shoutouts.dev",
  languages: ["Elixir"],
  provider_id: 5678,
  name: "shoutouts.dev",
  owner: "yeraydiazdiaz",
  primary_language: "Elixir",
  repo_created_at: ~U[2020-01-28 18:01:26Z],
  repo_updated_at: ~U[2020-11-27 03:20:08Z],
  stars: 3,
  url: "https://github.com/yeraydiazdiaz/shoutouts.dev"
}

{:ok, project} = Projects.create_project(admin, project_attrs)

project_attrs = %{
  description: "A Python implementation of Lunr.js 🌖",
  forks: 3,
  homepage_url: "http://lunr.readthedocs.io/",
  languages: ["Python", "JavaScript", "Makefile"],
  provider_id: 119_283_762,
  name: "lunr.py",
  owner: "yeraydiazdiaz",
  primary_language: "Python",
  repo_created_at: ~U[2018-01-28 18:01:26Z],
  repo_updated_at: ~U[2020-05-27 03:20:08Z],
  stars: 37,
  url: "https://github.com/yeraydiazdiaz/lunr.py"
}

{:ok, project} = Projects.create_project(admin, project_attrs)

shoutout_attrs = %{
  pinned: false,
  text: "Lunr.py is soooo cool!\n\nThanks so much!"
}

user = Accounts.get_user_by_username("johndoe")
Shoutouts.create_shoutout(user, project, shoutout_attrs)

shoutout_attrs = %{
  pinned: true,
  text:
    "Lunr.py is possibly the best package ever written by a human being in the history of the galaxy, you should win a Nobel prize for your work. Can you tell I'm trying to make a really long line?"
}

user = Accounts.get_user_by_username("janedoe")
Shoutouts.create_shoutout(user, project, shoutout_attrs)

project_attrs = %{
  description: "Simple layered loading of env files for your 12-factor app",
  forks: 0,
  homepage_url: "https://github.com/yeraydiazdiaz/envfiles",
  languages: ["Python"],
  provider_id: 1234,
  name: "envfiles",
  owner: "yeraydiazdiaz",
  primary_language: "Python",
  repo_created_at: ~U[2018-01-28 18:01:26Z],
  repo_updated_at: ~U[2020-05-27 03:20:08Z],
  stars: 37,
  url: "https://github.com/yeraydiazdiaz/envfiles"
}

{:ok, project} = Projects.create_project(user, project_attrs)

project_attrs = %{
  description: "A bit like Solr, but much smaller and not as bright",
  forks: 528,
  homepage_url: "https://github.com/olivernn/lunr.js",
  languages: ["JavaScript"],
  provider_id: 9876,
  name: "lunr.js",
  owner: "olivernn",
  primary_language: "JavaScript",
  repo_created_at: ~U[2020-01-28 18:01:26Z],
  repo_updated_at: ~U[2020-11-27 03:20:08Z],
  stars: 7231,
  url: "https://github.com/olivernn/lunr.js"
}

{:ok, project} = Projects.create_project(user, project_attrs)
