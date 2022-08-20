defmodule ExampleApplication.Repo.Migrations.AddUsersEmailVerified do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :email_verified, :boolean, default: false
    end
  end
end
