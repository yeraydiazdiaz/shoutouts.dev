defmodule Shoutouts.Shoutouts.Shoutout do
  use Ecto.Schema
  import Ecto.Changeset

  # Non-nullable AND default columns should be marked in the migration an
  # added to the validation_required changeset validation below
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]
  schema "shoutouts" do
    field :text, :string
    field :pinned, :boolean, default: false  # pinned by the owner
    field :flagged, :boolean, default: false  # flagged by the owner
    field :notified_at, :utc_datetime

    belongs_to :user, Shoutouts.Accounts.User
    belongs_to :project, Shoutouts.Projects.Project

    has_many :votes, Shoutouts.Shoutouts.Vote

    timestamps()
  end

  @doc false
  def changeset(shoutout, attrs) do
    shoutout
    |> cast(attrs, [
      :text,
      :pinned,
      :flagged,
      :user_id,
      :project_id,
      :notified_at
    ])
    |> validate_required([:text, :user_id, :project_id], message: "Must not be empty")
    |> validate_length(:text, min: 10, max: 250)
    |> assoc_constraint(:user)
    |> assoc_constraint(:project)
    |> unique_constraint([:user_id, :project_id])
  end
end
