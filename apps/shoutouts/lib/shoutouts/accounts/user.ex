defmodule Shoutouts.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @timestamps_opts [type: :utc_datetime]
  schema "users" do
    # full name
    field(:name, :string)
    # for notification in the future, defaults to provider's
    field(:email, :string)
    # in the provider
    field(:username, :string)
    # TODO: use a default
    field(:avatar_url, :string)
    # the signature to include in the shoutouts
    field(:signature, :string)
    # admin or user, the migration default must be a string
    field(:role, Ecto.Enum, values: [:admin, :user], default: :user)
    # lowercase, i.e. github, gitlab, bitbucket...
    field(:provider, Ecto.Enum, values: [:github], default: :github)
    # identifier on the provider
    field(:provider_id, :integer)
    # date the user created their account on the provider
    field(:provider_joined_at, :utc_datetime)
    # notifications preference
    field(:notify_when, Ecto.Enum, values: [:disabled, :weekly], default: :weekly)
    field(:twitter_handle, :string)

    has_many(:projects, Shoutouts.Projects.Project)
    has_many(:shoutouts, Shoutouts.Shoutouts.Shoutout)

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :name,
      :username,
      :email,
      :avatar_url,
      :signature,
      :role,
      :provider,
      :provider_id,
      :provider_joined_at,
      :notify_when,
      :twitter_handle
    ])
    |> validate_required([:name, :username, :email, :avatar_url, :provider, :provider_id])
    |> validate_format(:email, ~r/^[\w.!#$%&’*+\-\/=?\^`{|}~]+@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*$/)
    |> validate_length(:signature, max: 100)
    |> validate_format(:name, ~r/^[\p{L}\ 0-9]+$/u, message: "Unsupported character")
    |> validate_format(:signature, ~r/^[a-zA-Z0-9\ \.,!?\-\_'"\n#]+$/,
      message: "Must consist only alphanumeric characters and spaces"
    )
    |> validate_format(:twitter_handle, ~r/^@[A-Za-z0-9_]{1,15}+$/,
      message: "Twitter handles must start with an @ and be alphanumeric and underscors"
    )
    |> unique_constraint([:provider, :provider_id])
  end
end
