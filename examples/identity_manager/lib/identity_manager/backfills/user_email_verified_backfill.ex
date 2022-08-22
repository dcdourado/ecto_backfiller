defmodule IdentityManager.Backfills.UserEmailVerifiedBackfill do
  use EctoBackfiller, repo: IdentityManager.Repo

  alias IdentityManager.Users
  alias IdentityManager.Users.User

  @sleep_time :timer.seconds(1)

  @impl true
  def query, do: Ecto.Queryable.to_query(User)

  @impl true
  def step, do: 5

  @impl true
  def handle_batch(users) do
    Process.sleep(@sleep_time)

    Enum.each(users, fn user ->
      if user.email_verified_at do
        {:ok, _user} = Users.update(user, %{email_verified: true})
      end
    end)
  end
end
