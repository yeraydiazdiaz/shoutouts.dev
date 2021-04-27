defmodule Shoutouts.Repo.Migrations.ProjectsOptionalUser do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      modify(:user_id, :binary_id, null: true)
    end
  end
end
