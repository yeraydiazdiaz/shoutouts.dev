defmodule Shoutouts.Projects do
  @moduledoc """
  The Projects context.
  """

  import Ecto.Query, warn: false
  alias Shoutouts.Repo

  alias Shoutouts.Projects.Project
  alias Shoutouts.Shoutouts.Shoutout
  @default_order [desc: :inserted_at]

  @doc """
  Creates a project.

  ## Examples

      iex> create_project(%{field: value})
      {:ok, %Project{}}

      iex> create_project(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_project(user, attrs \\ %{}) do
    %Project{}
    |> Project.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  @doc """
  Gets a single project by owner and name.

  Raises `Ecto.NoResultsError` if the Project does not exist.

  ## Examples

      iex> get_project_by_owner_and_name("me", "mine")
      %Project{}

      iex> get_project_by_owner_and_name("me", "nope")
      ** (Ecto.NoResultsError)

  """
  def get_project_by_owner_and_name!(owner, name) do
    shoutouts_query =
      from(t in Shoutout,
        where: t.flagged == false,
        order_by: [desc: t.pinned, desc: t.inserted_at]
      )

    q =
      from(p in Project,
        where: p.owner == ^owner and p.name == ^name,
        preload: [shoutouts: ^shoutouts_query]
      )

    Repo.one!(q)
  end

  @doc """
  Gets a single project.

  Raises `Ecto.NoResultsError` if the Project does not exist.

  ## Examples

      iex> get_project!(123)
      %Project{}

      iex> get_project!(456)
      ** (Ecto.NoResultsError)

  """
  def get_project!(id) do
    Repo.get!(Project, id)
    |> Repo.preload(:user)
  end

  @doc """
  Returns the list of projects.

  ## Examples

      iex> list_projects()
      [%Project{}, ...]

  """
  def list_projects do
    Repo.all(
      from(p in Project,
        preload: [:user],
        order_by: ^@default_order
      )
    )
  end

  @doc """
  Returns the list of projects for a user with a specific username.

  ## Examples

      iex> list_projects_for_username("yeray")
      [%Project{}, ...]

  """
  def list_projects_for_username(username) do
    Repo.all(
      from(p in Project,
        join: u in assoc(p, :user),
        where: u.username == ^username,
        order_by: ^@default_order
      )
    )
  end

  @doc """
  Returns the list of projects 3-lists [id, names with owner, number of shoutouts] for a user.

  ## Examples

      iex> project_summary_for_username("yeray")
      [[123, "awesome", "project", 3]]

  """
  def project_summary_for_username(username) do
    Repo.all(
      from(
        p in Project,
        join: u in assoc(p, :user),
        left_join: t in assoc(p, :shoutouts),
        where: u.username == ^username,
        where: not t.flagged or is_nil(t.id),
        group_by: [p.id, p.owner, p.name],
        select: [p.id, p.owner, p.name, count(t.id)],
        order_by: [desc: count(t.id)]
      )
    )
  end

  def top_languages_by_projects(top_n) do
    Repo.all(
      from(
        p in Project,
        group_by: p.primary_language,
        select: [p.primary_language, count(p.id)],
        order_by: [desc: count(p.id)],
        limit: ^top_n
      )
    )
  end

  def top_projects_by_language_and_shoutouts(language, top_n) do
    Repo.all(
      from(
        p in Project,
        left_join: t in assoc(p, :shoutouts),
        where: p.primary_language == ^language,
        group_by: [p.owner, p.name],
        select: [p.owner, p.name, count(t.id)],
        order_by: [desc: count(t.id)],
        limit: ^top_n
      )
    )
  end

  def summary_by_languages(top_n_languages, top_n_projects) do
    top_languages_by_projects(top_n_languages)
    |> Enum.map(fn [lang, project_count] ->
      [lang, project_count, top_projects_by_language_and_shoutouts(lang, top_n_projects)]
    end)
  end

  @doc """
  Performs a search in the Repo returning the matching Projects.
  """
  def search(terms) do
    terms =
      terms
      |> String.replace("%", "\\%")
      |> String.split()

    query = from(p in Project, order_by: ^@default_order)

    # TODO: maybe use full text search on description as well?
    query =
      terms
      |> Enum.reduce(query, fn term, q ->
        from(p in q,
          where:
            fragment("name % ?", ^term) or
              fragment("owner % ?", ^term) or
              fragment("primary_language % ?", ^term)
        )
      end)

    Repo.all(query)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking Project changes.

  ## Examples

      iex> change_project(project)
      %Ecto.Changeset{source: %Project{}}

  """
  def change_project(%Project{} = project, attrs \\ %{}) do
    Project.changeset(project, attrs)
  end

  @doc """
  Updates a project.

  ## Examples

      iex> update_project(project, %{field: new_value})
      {:ok, %Project{}}

      iex> update_project(project, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_project(%Project{} = project, attrs) do
    project
    |> Project.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Project.

  ## Examples

      iex> delete_project(project)
      {:ok, %Project{}}

      iex> delete_project(project)
      {:error, %Ecto.Changeset{}}

  """
  def delete_project(%Project{} = project) do
    Repo.delete(project)
  end

  @doc """
  Returns a string in the form owner/name for a Project.
  """
  def name_with_owner(%Project{} = project) do
    "#{project.owner}/#{project.name}"
  end

  @doc """
  Returns a list of projects that match a list of [owner, name] lists.

  ## Examples

    iex> list_projects_for_username([["yeraydiazdiaz", "lunr.py"], ["not-a-user", "foobar"]])
    [%Project{owner: "yeraydiazdiaz", name: "lunr.py"}]
  """
  def list_with_owners_and_names(owners_and_names) do
    query =
      owners_and_names
      |> Enum.reduce(
        # where: false is required for compiling
        from(p in Project, where: false),
        fn [owner, name], q ->
          from(p in q, or_where: p.owner == ^owner and p.name == ^name)
        end
      )

    Repo.all(query)
  end

  def refresh_project(project, provider_app) do
    client = provider_app.client()
    with {:ok, project_info} <- provider_app.project_info(client, project.owner, project.name) do
      update_project(project, project_info)
    else
      {:error, response} -> {:error, response}
    end
  end
end
