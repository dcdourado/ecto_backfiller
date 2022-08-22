defmodule IdentityManager.Repo do
  use Ecto.Repo,
    otp_app: :identity_manager,
    adapter: Ecto.Adapters.Postgres
end
