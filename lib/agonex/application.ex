defmodule Agonex.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @config_schema [
    host: [
      type: :string,
      default: "localhost"
    ],
    port: [
      type: :pos_integer
    ],
    health_interval: [
      type: :pos_integer,
      default: 5000
    ],
    grpc_opts: [
      type: :keyword_list,
      default: []
    ]
  ]

  def start(_type, _args) do
    config =
      Application.get_all_env(:agonex)
      |> NimbleOptions.validate!(@config_schema)
      |> Keyword.put_new_lazy(:port, &sdk_env_port/0)

    client_opts = Keyword.take(config, [:host, :port, :grpc_opts, :health_interval])

    children = [
      {Task.Supervisor, name: Agonex.TaskSupervisor},
      {Agonex.Client, client_opts}
    ]

    opts = [strategy: :one_for_one, name: Agonex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp sdk_env_port,
    do: System.get_env("AGONES_SDK_GRPC_PORT", "9357") |> String.to_integer()
end
