defmodule Shoutouts.Shoutouts do
  @moduledoc """
  The Shoutouts context.
  """

  import Ecto.Query, warn: false
  alias Shoutouts.Repo

  alias Shoutouts.Shoutouts.Shoutout
  alias Shoutouts.Shoutouts.Vote

  @default_order [desc: :inserted_at]

  @doc """
  Creates a shoutout.

  ## Examples

      iex> create_shoutout(user, project, %{field: value})
      {:ok, %Shoutout{}}

      iex> create_shoutout(user, project, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_shoutout(user, project, attrs \\ %{}) do
    attrs =
      attrs
      |> Map.put(:user_id, user.id)
      |> Map.put(:project_id, project.id)

    %Shoutout{}
    |> Shoutout.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a single shoutout.

  Raises `Ecto.NoResultsError` if the Shoutout does not exist.

  ## Examples

      iex> get_shoutout!(123)
      %Shoutout{}

      iex> get_shoutout!(456)
      ** (Ecto.NoResultsError)

  """
  def get_shoutout!(id) do
    Repo.get!(Shoutout, id)
    |> Repo.preload(:user)
    |> Repo.preload(:project)
  end

  @doc """
  Returns the list of shoutouts.

  ## Examples

      iex> list_shoutouts()
      [%Shoutout{}, ...]

  """
  def list_shoutouts do
    Repo.all(
      from(p in Shoutout,
        order_by: ^@default_order
      )
    )
  end

  @doc """
  Returns the list of shoutouts for a project identified by owner/name.

  ## Examples

      iex> list_shoutouts_for_project("yeray", "mine")
      [%Shoutout{}, ...]

      iex> list_shoutouts_for_project("yeray", "nope")
      []

  """
  def list_shoutouts_for_project(owner, name) do
    Repo.all(
      from(t in Shoutout,
        join: p in assoc(t, :project),
        where: p.owner == ^owner,
        where: p.name == ^name,
        where: t.flagged == false,
        # TODO: use joining instead of preloading
        preload: [:user],
        order_by: ^@default_order
      )
    )
  end

  @doc """
  Returns the flagged shoutouts for a project identified by owner/name.

  ## Examples

      iex> list_flagged_shoutouts_for_project("yeray", "mine")
      [%Shoutout{}, ...]

  """
  def list_flagged_shoutouts_for_project(owner, name) do
    Repo.all(
      from(t in Shoutout,
        join: p in assoc(t, :project),
        where: p.owner == ^owner,
        where: p.name == ^name,
        where: t.flagged == true,
        preload: [:user],
        order_by: ^@default_order
      )
    )
  end

  @doc """
  Returns the list of shoutout text and its project for a user by their username.

  ## Examples

      iex> list_shoutouts_for_project("yeraydiazdiaz")
      [["Amazing", false, "yeray", "mine"]]

  """
  def list_shoutouts_for_user(username) do
    Repo.all(
      from(t in Shoutout,
        join: u in assoc(t, :user),
        join: p in assoc(t, :project),
        where: u.username == ^username,
        order_by: ^@default_order,
        select: [t.text, t.pinned, p.owner, p.name]
      )
    )
  end

  @doc """
  Returns the number of flagged shoutouts by a user identified by their username.

  Optionally pass an owner's username fo filter for projects owned by them.

  ## Examples

      iex> count_flagged_shoutouts_for_user_and_owner("yeraydiazdiaz")
      1

      iex> count_flagged_shoutouts_for_user_and_owner("yeraydiazdiaz", "johndoe")
      0

  """
  def count_flagged_shoutouts_for_user_and_owner(user_id, owner_id \\ nil) do
    query =
      from(t in Shoutout,
        where: t.user_id == ^user_id,
        where: t.flagged,
        select: count()
      )

    query =
      if owner_id != nil,
        do:
          from(t in query,
            join: p in assoc(t, :project),
            where: p.user_id == ^owner_id
          ),
        else: query

    Repo.one(query)
  end

  def count_owners_flagged_user(user_id) do
    Repo.one(
      from(t in Shoutout,
        join: p in assoc(t, :project),
        where: t.user_id == ^user_id,
        where: t.flagged,
        select: count(p.user_id, :distinct)
      )
    )
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking Shoutout changes.

  ## Examples

      iex> change_shoutout(shoutout, %{text: "Hello"})
      %Ecto.Changeset{source: %Shoutout{}}

  """
  def change_shoutout(%Shoutout{} = shoutout, attrs \\ %{}) do
    Shoutout.changeset(shoutout, attrs)
  end

  @doc """
  Updates a shoutout.

  ## Examples

      iex> update_shoutout(shoutout, %{field: new_value})
      {:ok, %Shoutout{}}

      iex> update_shoutout(shoutout, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_shoutout(%Shoutout{} = shoutout, attrs) do
    shoutout
    |> Shoutout.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Shoutout.

  ## Examples

      iex> delete_shoutout(shoutout)
      {:ok, %Shoutout{}}

      iex> delete_shoutout(shoutout)
      {:error, %Ecto.Changeset{}}

  """
  def delete_shoutout(%Shoutout{} = shoutout) do
    Repo.delete(shoutout)
  end

  @doc """
  Creates a vote for a Shoutout from a user and vote type.

  ## Examples

      iex> vote_shoutout(shoutout, user, :up)
      {:ok, %Shoutout{}}

      iex> vote_shoutout(shoutout, user, 1)
      {:error, %Ecto.Changeset{}}

  """
  def vote_shoutout(%Shoutout{} = shoutout, user, type) do
    attrs = %{
      type: type,
      shoutout_id: shoutout.id,
      user_id: user.id
    }

    %Vote{}
    |> Vote.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Sets the pinned flag to true on a shoutout.

  ## Examples

      iex> pin_shoutout(shoutout)
      {:ok, %Shoutout{}}

  """
  def pin_shoutout(%Shoutout{} = shoutout) do
    update_shoutout(shoutout, %{pinned: true})
  end

  @doc """
  Sets the pinned flag to false on a shoutout.

  ## Examples

      iex> unpin_shoutout(shoutout)
      {:ok, %Shoutout{}}

  """
  def unpin_shoutout(%Shoutout{} = shoutout) do
    update_shoutout(shoutout, %{pinned: false})
  end

  @doc """
  Sets flagged to true on a shoutout.

  ## Examples

      iex> pin_shoutout(shoutout)
      {:ok, %Shoutout{}}

  """
  def flag_shoutout(%Shoutout{} = shoutout) do
    update_shoutout(shoutout, %{flagged: true})
  end

  @doc """
  Sets flagged to false on a shoutout.

  ## Examples

      iex> unflag_shoutout(shoutout)
      {:ok, %Shoutout{}}

  """
  def unflag_shoutout(%Shoutout{} = shoutout) do
    update_shoutout(shoutout, %{flagged: false})
  end

  def badge_for_project(owner, name) do
    case list_shoutouts_for_project(owner, name) do
      [] -> nil
      shoutouts -> render_badge(length(shoutouts))
    end
  end

  def render_badge(num_shoutouts, scale \\ 1) do
    width = 106 * scale
    height = 20 * scale
    font_size = 110 * scale
    text_length = 590 * scale
    text_x = 365 * scale
    count_x = 885 * scale
    text_count_y = 140 * scale
    # 73
    text_width = width * 0.7

    """
      <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="#{
      width
    }" height="#{height}">
        <linearGradient id="s" x2="0" y2="100%">
          <stop offset="0" stop-color="#bbb" stop-opacity=".1" />
          <stop offset="1" stop-opacity=".1" />
        </linearGradient>
        <clipPath id="r">
          <rect width="#{width}" height="#{height}" rx="3" fill="#fff" />
        </clipPath>
        <g clip-path="url(#r)">
          <rect width="#{text_width}" height="#{height}" fill="#2b2d42" />
          <rect x="#{text_width}" width="#{width - text_width}" height="#{height}" fill="#cf093f" />
          <rect width="#{width}" height="#{height}" fill="url(#s)" />
        </g>
        <g fill="#fff" text-anchor="middle" font-family="Verdana,Geneva,DejaVu Sans,sans-serif" text-rendering="geometricPrecision" font-size="#{
      font_size
    }">
          <text x="#{text_x}" y="#{text_count_y}" transform="scale(.1)" textLength="#{text_length}">shoutouts</text>
          <text x="#{count_x}" y="#{text_count_y}" transform="scale(.1)">#{
      to_short_notation(num_shoutouts)
    }</text>
        </g>
      </svg>
    """
  end

  defp to_short_notation(number) do
    case number do
      number when number > 1_000_000 -> "#{div(number, 1_000_000)}M"
      number when number > 1000 -> "#{div(number, 1000)}K"
      number -> "#{number}"
    end
  end
end
