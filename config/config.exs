import Config

if Mix.env() in [:test, :dev] do
  config :ecto_backfiller, ecto_repos: [ExampleApplication.Repo]

  config :ecto_backfiller, ExampleApplication.Repo,
    database: "example_application_repo",
    username: "postgres",
    password: "postgres",
    hostname: "localhost"
end
