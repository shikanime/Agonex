defmodule Agonex.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @config_schema [
    health_interval: [
      type: :pos_integer
    ],
    grpc_options: [
      type: :keyword_list
    ]
  ]

  def start(_type, _args) do
    config =
      Application.get_all_env(:agonex)
      |> NimbleOptions.validate!(@config_schema)

    client_opts =
      config
      |> Keyword.take([:grpc_options, :health_interval])
      |> Keyword.put(:watcher_supervisor, Agonex.WatcherSupervisor)
      |> Keyword.put(:name, Agonex.Client)

    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: Agonex.WatcherSupervisor},
      {Agonex.Client, client_opts}
    ]

    opts = [strategy: :one_for_one, name: Agonex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
