defmodule Shoutouts.Repo.Migrations.AddProviderNodeId do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add(:provider_node_id, :string, null: true)
      add(:previous_owner_names, {:array, :string}, default: [], null: false)
    end
  end
end
