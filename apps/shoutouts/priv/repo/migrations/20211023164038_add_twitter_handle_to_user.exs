defmodule Shoutouts.Repo.Migrations.AddTwitterHandleToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:twitter_handle, :string, null: true)
    end
  end
end
