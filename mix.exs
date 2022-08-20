defmodule EctoBackfiller.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_backfiller,
      version: "0.1.0-dev",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "EctoBackfiller",
      docs: [
        main: "EctoBackfiller",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {EctoBackfiller.Application, []}
    ]
  end

  defp deps do
    [
      {:gen_stage, "~> 1.1.2"},
      {:ex_doc, "~> 0.28.0", only: :dev},
      {:ecto_sql, "~> 3.8.3"},
      {:postgrex, ">= 0.0.0"}
    ]
  end
end
