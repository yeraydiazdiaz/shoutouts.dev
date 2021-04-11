defmodule Shoutouts.Projects.Registration do
  import Ecto.Changeset

  defstruct [:url_or_owner_name]

  @types %{url_or_owner_name: :string}

  def changeset(%Shoutouts.Projects.Registration{} = registration, attrs) do
    {registration, @types}
    |> cast(attrs, [:url_or_owner_name])
  end

  def validate_changeset(%Shoutouts.Projects.Registration{} = registration, attrs) do
    changeset(registration, attrs)
    |> validate_required(:url_or_owner_name)
    |> validate_format(:url_or_owner_name, ~r/^(?:https:\/\/github\.com\/)?([\w-\.]+?)\/([\w-\.]+)$/,
      message: "A GitHub project URL or owner/name is required"
    )
  end
end
