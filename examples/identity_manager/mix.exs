defmodule IdentityManager.MixProject do
  use Mix.Project

  def project do
    [
      app: :identity_manager,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {IdentityManager.Application, []}
    ]
  end

  defp deps do
    [
      {:ecto_backfiller, path: "../.."},
      {:ecto, "~> 3.11.1"},
      {:ecto_sql, "~> 3.11.1"},
      {:postgrex, ">= 0.0.0"}
    ]
  end
end
