defmodule Shoutouts.Projects.Registration do
  import Ecto.Changeset

  defstruct [:url_or_owner_name, :owner, :name, :provider_project]

  @types %{url_or_owner_name: :string, name: :string, owner: :string, provider_project: :string}
  @regex ~r/^(?:https:\/\/github\.com\/)?([\w-]+?)\/([\w-\.]+)$/

  def changeset(%Shoutouts.Projects.Registration{} = registration, attrs) do
    {registration, @types}
    |> cast(attrs, [:url_or_owner_name])
  end

  @doc """
  Validates the changeset. Split from the normal changeset/2 to avoid validating
  on newly created changesets which will always contain errors.
  """
  def validate_changeset(%Shoutouts.Projects.Registration{} = registration, attrs) do
    changeset =
      changeset(registration, attrs)
      |> validate_required(:url_or_owner_name)
      |> validate_format(:url_or_owner_name, @regex,
        message: "A GitHub project URL or owner/name is required"
      )

    if changeset.valid? do
      [_, owner, name] = Regex.run(@regex, changeset.changes.url_or_owner_name)

      changeset
      |> change(%{owner: owner, name: name})
      |> validate_project()
    else
      changeset
    end
  end

  defp validate_project(changeset) do
    # TODO: this makes a request for any valid URL or owner/name, we should rate limit
    case Shoutouts.Projects.validate_registration(changeset.changes.owner, changeset.changes.name) do
      {:ok, project} ->
        change(changeset, %{provider_project: project})

      {:error, :no_such_repo} ->
        add_error(
          changeset,
          :url_or_owner_name,
          "The project does not exist or is not public, please check the URL for typos"
        )

      {:error, :already_exists} ->
        add_error(changeset, :url_or_owner_name, "The project has already been registered")

      {:error, _} ->
        add_error(
          changeset,
          :url_or_owner_name,
          "There was an error trying to validate the project, please try again later"
        )
    end
  end
end
