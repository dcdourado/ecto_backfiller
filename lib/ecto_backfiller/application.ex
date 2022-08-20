defmodule EctoBackfiller.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ExampleApplication.Repo
    ]

    opts = [strategy: :one_for_one, name: EctoBackfiller.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
