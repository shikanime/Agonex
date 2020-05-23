defmodule HelloAgones.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      :ranch.child_spec(HelloAgones.Server, :ranch_tcp, [port: 7654], :echo_protocol, [])
      # Starts a worker by calling: HelloAgones.Worker.start_link(arg)
      # {HelloAgones.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HelloAgones.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
