defmodule Agonex.MixProject do
  use Mix.Project

  @version "0.2.0-beta.1"

  def project do
    [
      app: :agonex,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      docs: docs(),
      deps: deps(),
      package: package(),
      description: "Kubernetes Agones SDK"
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
      {:ex_doc, "~> 0.22.1", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Shikanime Deva"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/Shikanime/Agonex"},
      files: ~w(lib LICENSE.md mix.exs README.md)
    ]
  end

  defp docs do
    [
      main: "Agonex",
      source_ref: "v#{@version}",
      source_url: "https://github.com/Shikanime/Agonex"
    ]
  end
end
