defmodule Shoutouts.Repo.Migrations.AddShoutoutsNotifiedAt do
  use Ecto.Migration

  def change do
    alter table(:shoutouts) do
     add(:notified_at, :utc_datetime, null: true)
    end
  end
end
