# IdentityManager

Example application using local `ecto_backfiller` to demonstrate how to use it.

## Installation

Execute the following commands
```
docker-compose up -d
mix deps.get
mix compile
mix ecto.create
mix ecto.migrate
mix run priv/repo/seeds.exs
```

## Usage

```
iex -S mix

alias IdentityManager.Backfills.UserEmailVerifiedBackfill
:ok = UserEmailVerifiedBackfill.start_link()
:ok = UserEmailVerifiedBackfill.add_consumer()
:ok = UserEmailVerifiedBackfill.start()
```
