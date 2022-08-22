defmodule EctoBackfiller.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_backfiller,
      version: "0.1.0-dev",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "EctoBackfiller",
      source_url: "https://github.com/dcdourado/ecto_backfiller",
      docs: [
        main: "EctoBackfiller",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:gen_stage, "~> 1.1.2"},
      {:ecto, "~> 3.8.4"},
      {:ecto_sql, "~> 3.8.3"},
      {:postgrex, ">= 0.0.0"},
      {:ex_doc, "~> 0.28.0", only: :dev}
    ]
  end

  defp description() do
    "A back-pressured backfill executor for Ecto."
  end

  defp package() do
    [
      files: ~w(lib priv .formatter.exs mix.exs README.md LICENSE),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/dcdourado/ecto_backfiller"}
    ]
  end
end
