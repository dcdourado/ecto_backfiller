defmodule ExampleApplication.Users do
  alias ExampleApplication.Repo
  alias ExampleApplication.Users.User

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
