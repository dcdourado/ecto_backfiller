import Config

config :identity_manager, ecto_repos: [IdentityManager.Repo]

config :identity_manager, IdentityManager.Repo,
  database: "example_application_repo",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"
