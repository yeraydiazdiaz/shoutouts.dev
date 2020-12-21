defmodule Shoutouts.Repo.Migrations.Initial do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm;"

    # Users
    create table(:users, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string, null: false)
      add(:username, :string, null: false)
      add(:email, :string, null: false)
      add(:avatar_url, :string, null: false)
      add(:signature, :string, default: "")
      add(:role, :string, default: "user")
      add(:provider, :string, null: false, default: "github")
      add(:provider_id, :bigint, null: false)
      add(:provider_joined_at, :utc_datetime, null: false)

      # This produces a Postgres type `timestamp(0) without time zone`
      # however the timezone information is stored
      timestamps(type: :utc_datetime)
    end

    create(unique_index(:users, [:provider, :provider_id]))
    create(index(:users, [:username]))

    # Projects
    create table(:projects, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:pinned_only, :boolean, default: false)
      add(:provider, :string, null: false, default: "github")
      add(:provider_id, :bigint, null: false)
      add(:owner, :string, null: false)
      add(:name, :string, null: false)
      add(:repo_created_at, :utc_datetime)
      add(:repo_updated_at, :utc_datetime)
      add(:url, :string)
      add(:description, :text)
      add(:homepage_url, :string)
      add(:primary_language, :string)
      add(:languages, {:array, :string})
      add(:stars, :integer)
      add(:forks, :integer)
      add(:user_id, references(:users, type: :binary_id), null: false)
      timestamps(type: :utc_datetime)
    end

    create(unique_index(:projects, [:provider_id]))
    create(unique_index(:projects, [:owner, :name]))
    create(index(:projects, [:owner], using: "btree"))
    create(index(:projects, [:name], using: "btree"))
    # TODO: GIN does not seem to work for our use case, still a win over seq scan
    [:owner, :name, :primary_language]
    |> Enum.each(fn col -> execute "CREATE INDEX projects_#{col}_trgm_index ON projects USING GIST (#{col} gist_trgm_ops)" end)

    # Shoutouts
    create table(:shoutouts, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:text, :text, null: false)
      add(:pinned, :boolean, default: false)
      add(:flagged, :boolean, default: false)
      add(:user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false)
      add(:project_id, references(:projects, type: :binary_id, on_delete: :delete_all), null: false)
      timestamps(type: :utc_datetime)
    end

    create(unique_index(:shoutouts, [:user_id, :project_id]))

    # Votes
    create table(:votes, primary_key: false) do
      add(:type, :string, null: false)
      add(:id, :binary_id, primary_key: true)
      add(:shoutout_id, references(:shoutouts, type: :binary_id, on_delete: :delete_all), null: false)
      add(:user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false)
      timestamps(type: :utc_datetime)
    end

    create(unique_index(:votes, [:user_id, :shoutout_id]))
  end
end
