defmodule Agonex.MixProject do
  use Mix.Project

  def project do
    [
      app: :agonex,
      version: "0.2.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Agonex.Application, []}
    ]
  end

  defp deps do
    [
      {:nimble_options, "~> 0.2"},
      {:grpc, "~> 0.5.0-beta.1"},
      {:connection, "~> 1.0"},
      {:ex_doc, "~> 0.22.1", only: :dev, runtime: false}
    ]
  end
end
