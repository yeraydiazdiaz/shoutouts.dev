defmodule Shoutouts.Projects do
  @moduledoc """
  The Projects context.
  """
  require Logger
  import Ecto.Query, warn: false

  alias Shoutouts.Repo
  alias Shoutouts.Projects.Project
  alias Shoutouts.Provider
  alias Shoutouts.Shoutouts.Shoutout
  @default_order [desc: :inserted_at]

  @doc """
  Creates a project with an owner.

  ## Examples

      iex> create_project(%User{}, %{field: value})
      {:ok, %Project{}}

      iex> create_project(%User{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_project(user, attrs) do
    %Project{}
    |> Project.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  @doc """
  Creates a project with no owner.

  ## Examples

      iex> create_project(%{field: value})
      {:ok, %Project{}}

      iex> create_project(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_project(attrs) do
    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a single project by owner and name. User and unflagged shoutouts are preloaded.

  Raises `Ecto.NoResultsError` if the Project does not exist.

  ## Examples

      iex> get_project_by_owner_and_name!("me", "mine")
      %Project{}

      iex> get_project_by_owner_and_name!("me", "nope")
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
        preload: [:user],
        preload: [shoutouts: ^shoutouts_query]
      )

    Repo.one!(q)
  end

  @doc """
  Gets a single project by owner and name. User and unflagged shoutouts are preloaded.

  Returns {:ok, project} or {:error, :no_such_repo}

  ## Examples

      iex> get_project_by_owner_and_name("me", "mine")
      {:ok, %Project{}}

      iex> get_project_by_owner_and_name("me", "nope")
      {:error, :no_such_project}

  """
  def get_project_by_owner_and_name(owner, name) do
    shoutouts_query =
      from(t in Shoutout,
        where: t.flagged == false,
        order_by: [desc: t.pinned, desc: t.inserted_at]
      )

    q =
      from(p in Project,
        where: p.owner == ^owner and p.name == ^name,
        preload: [:user],
        preload: [shoutouts: ^shoutouts_query]
      )

    case Repo.one(q) do
      nil -> {:error, :no_such_project}
      project -> {:ok, project}
    end
  end

  @doc """
  Resolves a single project by owner and name including any previous owner/names.

  User and unflagged shoutouts are preloaded.

  Returns {:ok, project} or {:error, :no_such_repo}

  ## Examples

      iex> resolve_project_by_owner_and_name("me", "mine")
      {:ok, %Project{}}

      iex> resolve_project_by_owner_and_name("me", "oldmine")
      {:ok, %Project{}}

      iex> resolve_project_by_owner_and_name("me", "nope")
      {:error, :no_such_project}

  """
  def resolve_project_by_owner_and_name(owner, name) do
    shoutouts_query =
      from(t in Shoutout,
        where: t.flagged == false,
        order_by: [desc: t.pinned, desc: t.inserted_at]
      )

    owner_name = "#{owner}/#{name}"

    direct_match_query =
      from(p in Project,
        where: p.owner == ^owner and p.name == ^name,
        preload: [:user],
        preload: [shoutouts: ^shoutouts_query]
      )

    previous_match_query =
      from(p in Project,
        where: ^owner_name in p.previous_owner_names,
        preload: [:user],
        preload: [shoutouts: ^shoutouts_query]
      )

    with nil <- Repo.one(direct_match_query),
         nil <- Repo.one(previous_match_query) do
      {:error, :no_such_project}
    else
      project -> {:ok, project}
    end
  end

  @doc """
  Returns whether a project by owner and name.

  ## Examples

      iex> project_exists?("me", "mine")
      {:ok, %Project{}}

      iex> get_project_by_owner_and_name("me", "nope")
      ** (Ecto.NoResultsError)

  """
  def project_exists?(owner, name, provider \\ :github) do
    Repo.exists?(
      from(p in Project,
        where: p.owner == ^owner and p.name == ^name and p.provider == ^provider
      )
    )
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
        where: not is_nil(p.primary_language),
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

  @doc """
  Returns the provider module for a specific user, defaulting to the provider
  set in the application env's :default_provider.
  """
  def provider_for_user(_user) do
    # TODO: Returns the provider for a particular user
    # Would it be possible for a single user to have more than one provider?
    Application.get_env(:shoutouts, :default_provider, Shoutouts.Providers.GitHub)
  end

  @doc """
  Returns an error tuple with user's repositories on their provider.

  ## Examples:

    iex> user_repositories("yeraydiazdiaz")
    {:ok, ["yeraydiazdiaz/shoutouts.dev"]}

    iex> user_repositories("gotnorepos")
    {:ok, []}

    iex> user_repositories("gotnointernet")
    {:error, :nxdomain}
  """
  def user_repositories(user) do
    Logger.debug("Getting repos")

    provider_for_user(user)
    |> Provider.user_repositories(user.username)
  end

  @doc """
  Returns a project's information using a user provider given a owner and name strings.
  """
  def project_info(user, owner, name) do
    provider_for_user(user)
    |> Provider.project_info(owner, name)
  end

  def refresh_projects(days_since_last_update, limit \\ 0) do
    update_at_threshold = DateTime.add(DateTime.utc_now(), -days_since_last_update * 24 * 3600)

    base_query =
      from(p in Project,
        where: is_nil(p.updated_at) and p.inserted_at <= ^update_at_threshold,
        or_where: p.updated_at <= ^update_at_threshold,
        order_by: ^@default_order
      )

    query =
      if limit > 0 do
        from(base_query, limit: ^limit)
      else
        base_query
      end

    errors =
      Repo.all(query)
      |> Enum.reduce([], fn project, errors ->
        with {:ok, project} <- refresh_project(project) do
          Logger.info("Updated #{project.owner}/#{project.name}")
          errors
        else
          {:error, _response} ->
            Logger.error("Could not update project")
            [project.id | errors]
        end
      end)

    case length(errors) do
      0 -> {:ok, []}
      _ -> {:error, errors}
    end
  end

  def refresh_project(project) do
    # TODO: Although GitHub does automatic redirection and the API will return the new
    # information if you provide an older owner/name we should still use the node ID
    with {:ok, project_info} <-
           provider_for_user(project.user) |> Provider.project_info(project.owner, project.name) do
      # TODO: if the project's info has not changed the below will _not_ change
      # update_at, which means the project will be picked up again in the next run
      if project_info.owner != project.owner or project_info.name != project.name do
        params =
          Map.from_struct(project_info)
          |> Map.put(:previous_owner_names, [
            "#{project.owner}/#{project.name}" | project.previous_owner_names
          ])

        update_project(project, params)
      else
        update_project(project, Map.from_struct(project_info))
      end
    else
      {:error, response} -> {:error, response}
    end
  end

  @doc """
  Validates the registration of a project based on owner and name.

  The project must:
  1. Not already exist in the DB,
  2. Exist and be public in the provider (based on the providers API response)
  """
  def validate_registration(owner, name, provider \\ nil) do
    provider =
      if provider == nil,
        do: Application.get_env(:shoutouts, :default_provider, Shoutouts.Providers.GitHub)

    if project_exists?(owner, name) do
      {:error, :already_exists}
    else
      case Provider.project_info(provider, owner, name) do
        {:ok, :no_such_repo} -> {:error, :no_such_repo}
        {:ok, provider_project} -> {:ok, provider_project}
        {:error, _} -> {:error, :provider_error}
      end
    end
  end

  def claim_project(%Project{user_id: nil} = project, user) do
    project
    # this is necessary for put_assoc
    |> Repo.preload(:user)
    |> Project.changeset(%{})
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.update()
  end

  def sort_projects_by_owner_name(projects) do
    Enum.sort(
      projects,
      &(name_with_owner(&1) <= name_with_owner(&2))
    )
  end
end
