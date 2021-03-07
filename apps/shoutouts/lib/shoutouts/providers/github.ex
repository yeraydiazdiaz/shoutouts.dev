defmodule Shoutouts.Providers.GitHub do
  @moduledoc """
  Functions that interact with the GitHub API.

  This module requires a personal access token.
  """
  @behaviour Shoutouts.Provider
  alias Shoutouts.Providers.ProviderProject

  @base_middlewares [
    {Tesla.Middleware.BaseUrl, "https://api.github.com/"},
    Tesla.Middleware.JSON
  ]

  @impl true
  def client() do
    client(Application.get_env(:shoutouts, :github_token))
  end

  @impl true
  def client(token) do
    (@base_middlewares ++
       [
         {Tesla.Middleware.Headers,
          [
            {"accept", "application/vnd.github.machine-man-preview+json"},
            {"authorization", "bearer " <> token}
          ]}
       ])
    |> Tesla.client()
  end

  def user_starred_repos(client, login) do
    query = """
    {
      user(login: "#{login}") {
        starredRepositories {
          nodes {
            nameWithOwner
          }
        }
      }
    }
    """

    with {:ok, body} <- graphql(client, query) do
      repos = body["data"]["user"]["starredRepositories"]["nodes"]
      {:ok, Enum.map(repos, &Map.get(&1, "nameWithOwner"))}
    else
      response -> {:error, response}
    end
  end

  @impl true
  def user_repositories(client, login, cursor \\ nil) do
    # TODO: affiliations don't seem to include collaborations?
    after_param =
      if cursor == nil do
        ""
      else
        "after: \"#{cursor}\", "
      end

    query = """
    {
      user(login: "#{login}") {
        name
        login
        repositories(first: 100, #{after_param}affiliations: [OWNER, ORGANIZATION_MEMBER, COLLABORATOR], isFork: false, privacy: PUBLIC) {
          nodes {
            nameWithOwner
          }
          pageInfo {
            endCursor
            hasNextPage
          }
        }
      }
    }
    """

    with {:ok, body} <- graphql(client, query) do
      repositories = body["data"]["user"]["repositories"]
      # TODO: passing an invalid username raises because of nil nodes
      repos = Enum.map(repositories["nodes"], &Map.get(&1, "nameWithOwner"))

      case repositories["pageInfo"]["hasNextPage"] do
        false ->
          {:ok, repos}

        true ->
          {:ok, more_repos} =
            user_repositories(client, login, repositories["pageInfo"]["endCursor"])

          {:ok, repos ++ more_repos}
      end
    else
      response -> {:error, response}
    end
  end

  @impl true
  def project_info(client, repo_with_owner) do
    [owner, name] = String.split(repo_with_owner, "/")
    project_info(client, owner, name)
  end

  @impl true
  def project_info(client, owner, name) do
    query = """
    {
      repository(owner: "#{owner}", name: "#{name}") {
        databaseId
        owner {
          login
        }
        name
        createdAt
        updatedAt
        url
        description
        homepageUrl
        primaryLanguage {
          name
        }
        languages(last: 10) {
          nodes {
            name
          }
        }
        stargazers {
          totalCount
        }
        forks {
          totalCount
        }
      }
    }
    """

    # https://graphql.org/learn/serving-over-http/
    with {:ok, response} <- graphql(client, query) do
      repo = response["data"]["repository"]
      {:ok, parse_repo(repo)}
    else
      {:error, response} -> {:error, response}
    end
  end

  def parse_repo(nil) do
    :no_such_repo
  end

  def parse_repo(repo) do
    {:ok, created_at, _} = DateTime.from_iso8601(repo["createdAt"])
    {:ok, updated_at, _} = DateTime.from_iso8601(repo["updatedAt"])

    %ProviderProject{
      provider_id: repo["databaseId"],
      owner: repo["owner"]["login"],
      name: repo["name"],
      repo_created_at: created_at,
      repo_updated_at: updated_at,
      url: repo["url"],
      description: repo["description"],
      homepage_url: repo["homepageUrl"],
      primary_language: repo["primaryLanguage"]["name"],
      languages: repo["languages"]["nodes"] |> Enum.map(&Map.get(&1, "name")),
      stars: repo["stargazers"]["totalCount"],
      forks: repo["forks"]["totalCount"]
    }
  end

  def get(client, endpoint) do
    with {:ok, response} <- Tesla.get(client, endpoint),
         %{status: 200, body: body} <- response do
      {:ok, body}
    else
      response -> {:error, response}
    end
  end

  def post(client, endpoint, data \\ "") do
    with {:ok, response} <- Tesla.post(client, endpoint, data),
         %{status: 201, body: body} <- response do
      {:ok, body}
    else
      response -> {:error, response}
    end
  end

  def graphql(client, query) do
    # Wrap query in a single "query" map https://graphql.org/learn/serving-over-http/
    with {:ok, response} <-
           Tesla.post(client, "https://api.github.com/graphql", %{"query" => query}),
         %{status: 200, body: body} <- response do
      {:ok, body}
    else
      response -> {:error, response}
    end
  end
end
