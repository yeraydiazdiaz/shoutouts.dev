defmodule Shoutouts.Shoutouts.Vote do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]
  schema "votes" do
    field :type, Ecto.Enum, values: [:up, :down, :flag]
    belongs_to :shoutout, Shoutouts.Shoutouts.Shoutout
    belongs_to :user, Shoutouts.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:type, :shoutout_id, :user_id])
    |> validate_inclusion(:type, Ecto.Enum.values(Shoutouts.Shoutouts.Vote, :type))
    |> assoc_constraint(:shoutout)
    |> assoc_constraint(:user)
    |> unique_constraint([:shoutout_id, :user_id])
  end
end
