defmodule ExampleApplication.Repo do
  use Ecto.Repo,
    otp_app: :ecto_backfiller,
    adapter: Ecto.Adapters.Postgres
end
