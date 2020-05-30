defmodule HelloAgones.MixProject do
  use Mix.Project

  def project do
    [
      app: :hello_agones,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      releases: releases(),
      deps: deps()
    ]
  end

  # Run "mix help release" to learn about releases.
  defp releases do
    [
      hello_agones: [
        include_executables_for: [:unix],
        applications: [
          runtime_tools: :permanent,
          hello_agones: :permanent
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {HelloAgones.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ranch, "~> 1.7"},
      {:agonex, path: "../../"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
