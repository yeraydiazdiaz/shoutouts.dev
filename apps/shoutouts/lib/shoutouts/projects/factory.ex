defmodule Shoutouts.Factory do
  use ExMachina.Ecto, repo: Shoutouts.Repo

  def user_factory do
    %Shoutouts.Accounts.User{
      name: sequence(:name, &"User #{&1}"),
      username: sequence(:username, &"user-#{&1}"),
      email: sequence(:email, &"email-#{&1}@example.com"),
      avatar_url: sequence(:avatar_url, &"https://example.org/avatar/#{&1}"),
      provider: :github,
      provider_id: sequence(:provider_id, & &1),
      signature: sequence(:username, &"Signature no. #{&1}"),
      provider_joined_at: ~U[2014-02-20T16:58:32Z]
    }
  end

  def project_factory do
    %Shoutouts.Projects.Project{
      provider: :github,
      provider_id: sequence(:provider_id, fn x -> x end),
      provider_node_id: sequence(:provider_node_id, &"#{&1}"),
      owner: sequence(:owner, &"owner-#{&1}"),
      name: sequence(:name, &"name-#{&1}"),
      primary_language: sequence(:primary_language, ["python", "elixir", "rust", "javascript"]),
      description:
        sequence(:description, [
          "http client",
          "web framework",
          "machine learning",
          "text processing"
        ]),
      user: build(:user),
      previous_owner_names: []
    }
  end

  def shoutout_factory do
    %Shoutouts.Shoutouts.Shoutout{
      text: sequence(:text, &"This is amazing! v#{&1}"),
      user: build(:user),
      project: build(:project)
    }
  end

  def provider_project_factory(params \\ []) do
    pp = %Shoutouts.Providers.ProviderProject{
      provider_id: sequence(:provider_id, fn x -> x end),
      provider_node_id: sequence(:provider_node_id, &"#{&1}"),
      owner: sequence(:owner, &"owner-#{&1}"),
      name: sequence(:name, &"name-#{&1}"),
      primary_language: sequence(:primary_language, ["python", "elixir", "rust", "javascript"]),
      url: sequence(:url, &"https://github.com/owner-#{&1}/name-#{&1}"),
      description:
        sequence(:description, [
          "http client",
          "web framework",
          "machine learning",
          "text processing"
        ])
    }

    Enum.reduce(params, pp, fn {k, v}, acc -> Map.put(acc, k, v) end)
  end
end
