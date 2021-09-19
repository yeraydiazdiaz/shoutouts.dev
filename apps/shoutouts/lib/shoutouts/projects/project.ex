defmodule Shoutouts.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset

  # Non-nullable AND default columns should be marked in the migration an
  # added to the validation_required changeset validation below
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]
  schema "projects" do
    field(:pinned_only, :boolean, default: false)
    field(:provider, Ecto.Enum, values: [:github], default: :github)
    field(:provider_id, :integer)
    field(:provider_node_id, :string)
    field(:owner, :string)
    field(:name, :string)
    field(:repo_created_at, :utc_datetime)
    field(:repo_updated_at, :utc_datetime)
    field(:url, :string)
    field(:description, :string)
    field(:homepage_url, :string)
    field(:primary_language, :string)
    field(:languages, {:array, :string})
    field(:stars, :integer)
    field(:forks, :integer)
    # a list of "prev_org/prev_name" strings
    field(:previous_owner_names, {:array, :string})

    belongs_to(:user, Shoutouts.Accounts.User)

    has_many(:shoutouts, Shoutouts.Shoutouts.Shoutout)

    timestamps()
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [
      :pinned_only,
      :provider_id,
      :provider_node_id,
      :owner,
      :name,
      :repo_created_at,
      :repo_updated_at,
      :url,
      :description,
      :homepage_url,
      :primary_language,
      :languages,
      :stars,
      :forks,
      :previous_owner_names
    ])
    # TODO: add provider_node_id once projects have been updated
    |> validate_required([:provider_id, :pinned_only, :owner, :name, :description],
      message: "Must not be empty"
    )
    |> unique_constraint([:provider, :provider_id])
    # TODO: add :provider, :provider_node_id once projects have been updated
    |> unique_constraint([:owner, :name])
    |> validate_length(:description, min: 10, max: 2500)
    |> validate_format(:description, ~r/^\X+$/u, message: "Invalid character")
  end
end
