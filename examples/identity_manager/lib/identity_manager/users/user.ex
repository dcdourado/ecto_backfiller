defmodule IdentityManager.Users.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :email_verified_at, :naive_datetime
    field :email_verified, :boolean
    timestamps()
  end

  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, [:email, :email_verified_at, :email_verified])
    |> validate_required([:email])
  end
end
