defmodule Shoutouts.Projects.Registration do
  import Ecto.Changeset

  defstruct [:url_or_owner_name, :owner, :name]

  @types %{url_or_owner_name: :string, name: :string, owner: :string}
  @regex ~r/^(?:https:\/\/github\.com\/)?([\w-]+?)\/([\w-\.]+)$/

  def changeset(%Shoutouts.Projects.Registration{} = registration, attrs) do
    {registration, @types}
    |> cast(attrs, [:url_or_owner_name, :owner, :name])
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
    else
      changeset 
    end 
  end
end
