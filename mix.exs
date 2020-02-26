defmodule Agonex.MixProject do
  use Mix.Project

  def project do
    [
      app: :agonex,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:grpc, "~> 0.5.0-beta.1"},
      {:connection, "~> 1.0"}
    ]
  end
end
