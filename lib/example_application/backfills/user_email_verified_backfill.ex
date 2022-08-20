defmodule ExampleApplication.Backfills.UserEmailVerifiedBackfill do
  use EctoBackfiller, repo: ExampleApplication.Repo

  alias ExampleApplication.Users
  alias ExampleApplication.Users.User

  @impl true
  def query, do: Ecto.Queryable.to_query(User)

  @impl true
  def step, do: 5

  @impl true
  def handle_batch(users) do
    Enum.each(users, fn user ->
      if user.email_verified_at do
        {:ok, _user} = Users.update(user, %{email_verified: true})
      end
    end)
  end
end
