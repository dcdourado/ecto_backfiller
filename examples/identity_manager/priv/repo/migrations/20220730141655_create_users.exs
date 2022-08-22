defmodule IdentityManager.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:users) do
      add :email, :string, null: false
      add :email_verified_at, :naive_datetime
      timestamps()
    end
  end
end
