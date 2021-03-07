defmodule Shoutouts.Provider do
  @moduledoc """
  Provider behaviour, exposes a dynamically dispatched API for providers.

  Example:

  iex> Shoutouts.Provider.user_repositories(Shoutouts.Providers.GitHub, "yeraydiazdiaz")
  """

  @doc """
  Returns a Tesla client with auth token taken from configuration.
  """
  @callback client() :: Tesla.Client.t()

  @doc """
  Returns a Tesla client with the specified token.
  """
  @callback client(token :: binary()) :: TeslaClient.t()

  @doc """
  Returns a list of owner/name string for repos owned by the user.

  Note this includes co-owned repos.

  ## Examples

    iex> client() |> user_repositories("yeraydiazdiaz")
    {:ok, ["yeraydiazdiaz/shoutouts.dev", "yeraydiazdiaz/lunr.py"]}
  """
  @callback user_repositories(
              client :: TeslaClient.t(),
              login :: binary(),
              cursor :: integer()
            ) :: {:ok, [binary()]} | {:error, response :: Tesla.Env.t()}

  @callback project_info(
              client :: TeslaClient.t(),
              repo_with_owner :: binary()
            ) :: {:ok, Shoutouts.Providers.ProviderProject} | {:error, response :: Tesla.Env.t()}

  @callback project_info(
              client :: TeslaClient.t(),
              owner :: binary(),
              name :: binary()
            ) :: {:ok, Shoutouts.Providers.ProviderProject} | {:error, response :: Tesla.Env.t()}

  def user_repositories(implementation, login) do
    implementation.client()
    |> implementation.user_repositories(login)
  end

  def project_info(implementation, repo_with_owner) do
    implementation.client()
    |> implementation.project_info(repo_with_owner)
  end

  def project_info(implementation, owner, name) do
    implementation.client()
    |> implementation.project_info(owner, name)
  end
end
