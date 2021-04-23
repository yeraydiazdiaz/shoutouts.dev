defmodule Shoutouts.Repo.Migrations.AddUserNotificationPreference do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:notify_when, :string, null: false, default: "weekly")
    end
  end
end
