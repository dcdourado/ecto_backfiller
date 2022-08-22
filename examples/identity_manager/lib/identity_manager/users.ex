defmodule IdentityManager.Users do
  alias IdentityManager.Repo
  alias IdentityManager.Users.User

  def insert(params) do
    params
    |> User.changeset()
    |> Repo.insert()
  end

  def update(user, params) do
    user
    |> User.changeset(params)
    |> Repo.update()
  end
end
