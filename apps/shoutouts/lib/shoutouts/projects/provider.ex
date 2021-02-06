defmodule Shoutouts.ProviderApp do
  @type project_info_map :: %{
          provider_id: integer,
          owner: binary(),
          name: binary(),
          repo_created_at: DateTime.t(),
          repo_updated_at: DateTime.t(),
          url: binary(),
          description: binary(),
          homepage_url: binary(),
          primary_language: binary(),
          languages: [binary()],
          stars: integer,
          forks: integer
        }
  @callback client() :: Tesla.Client.t()
  @callback client(token :: binary()) :: TeslaClient.t()
  @callback user_repositories(
              client :: TeslaClient.t(),
              login :: binary(),
              cursor :: integer()
            ) :: {:ok, [binary()]} | {:error, response :: Tesla.Env.t()}
  @callback project_info(
              client :: TeslaClient.t(),
              repo_with_owner :: binary()
            ) :: {:ok, project_info_map()} | {:error, response :: Tesla.Env.t()}
  @callback project_info(
              client :: TeslaClient.t(),
              owner :: binary(),
              name :: binary()
            ) :: {:ok, project_info_map()} | {:error, response :: Tesla.Env.t()}
end
