defmodule Shoutouts.Providers.ProviderProject do
  @enforce_keys [
    :provider_id,
    :provider_node_id,
    :owner,
    :name,
    :url,
    :description,
    :primary_language
  ]
  defstruct [
    :provider_id,
    :provider_node_id,
    :owner,
    :name,
    :url,
    :description,
    :primary_language,
    :repo_created_at,
    :repo_updated_at,
    homepage_url: "",
    languages: [],
    stars: 0,
    forks: 0
  ]

  @type t :: %Shoutouts.Providers.ProviderProject{
          provider_id: integer,
          provider_node_id: binary(),
          owner: binary(),
          name: binary(),
          url: binary(),
          description: binary(),
          primary_language: binary(),
          repo_created_at: DateTime.t() | nil,
          repo_updated_at: DateTime.t() | nil,
          homepage_url: binary(),
          languages: [binary()],
          stars: integer,
          forks: integer
        }
end
