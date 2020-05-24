defmodule Agonex.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @config_schema [
    health_interval: [
      type: :pos_integer,
      default: 5000
    ],
    grpc_options: [
      type: :keyword_list,
      default: []
    ]
  ]

  def start(_type, _args) do
    config =
      Application.get_all_env(:agonex)
      |> NimbleOptions.validate!(@config_schema)

    client_opts = Keyword.take(config, [:grpc_options, :health_interval])

    children = [
      {Task.Supervisor, name: Agonex.TaskSupervisor},
      {Agonex.Client, client_opts}
    ]

    opts = [strategy: :one_for_one, name: Agonex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
