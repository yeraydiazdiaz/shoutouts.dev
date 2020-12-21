defmodule Shoutouts.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Shoutouts.Repo

  alias Shoutouts.Accounts.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets or creates a user from an Ueberauth.Auth struct.

  ## Examples

      iex> get_or_create_user_from_auth(auth)
      {:ok, %User{...}}

  """
  def get_or_create_user_from_auth(auth) do
    case Repo.get_by(User, provider_id: to_string(auth.uid)) do
      nil -> create_user_from_auth(auth)
      user -> {:ok, user}
    end
  end

  @doc """
  Creates a user from an Ueberauth.Auth struct.
  """
  def create_user_from_auth(auth) do
    # TODO: check against other providers
    {:ok, joined, 0} = DateTime.from_iso8601(auth.extra.raw_info.user["created_at"])

    create_user(%{
      email: auth.info.email,
      name: auth.info.name,
      username: auth.info.nickname,
      avatar_url: auth.info.image,
      provider: to_string(auth.provider),
      # TODO: this may only be required for GH
      provider_id: Integer.to_string(auth.uid),
      provider_joined_at: joined
    })
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a single user from their username.

  Returns nil if no user is found.
  Raises `Ecto.MultipleResultsError` if more than one User exists with that username.

  ## Examples

      iex> get_user_by_username("yeray")
      %User{}

      iex> get_user_by_username("nope")
      nil

      iex> get_user_by_username("joecommon")
      ** (Ecto.MultipleResultsError)

  """
  def get_user_by_username(username) do
    Repo.get_by(User, username: username)
  end

  @doc """
  Gets a single user from their email.

  Returns nil if no user is found.
  Raises `Ecto.MultipleResultsError` if more than one User exists with that email.

  ## Examples

      iex> get_user_by_email("yeray@example.com")
      %User{}

      iex> get_user_by_email("nope@example.com")
      nil

      iex> get_user_by_email("joecommon@example.com)
      ** (Ecto.MultipleResultsError)

  """
  def get_user_by_email(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a single user by ID.

  ## Examples

      iex> get_user(123)
      %User{}

      iex> get_user(456)
      nil

  """
  def get_user(id) do
    Repo.get(User, id)
  end

  @doc """
  Gets a single user by ID.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id) do
    Repo.get!(User, id)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking User changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  def seconds_since_provider_joined(%User{} = user) do
    DateTime.diff(DateTime.truncate(DateTime.utc_now(), :second), user.provider_joined_at)
  end
end
