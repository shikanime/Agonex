defmodule Agonex do
  @moduledoc """
  A SDK client for Agones.
  """

  @type duration :: non_neg_integer

  def start_link(url, opts \\ []) do
    name = Keyword.get(opts, :name, Agonex)

    task_sup_name = Module.concat(name, "TaskSupervisor")
    sup_name = Module.concat(name, "Supervisor")

    children = [
      {Task.Supervisor, name: task_sup_name},
      {Agonex.Client, [url, task_sup_name, opts]}
    ]

    Supervisor.start_link(children, strategy: :rest_for_one, name: sup_name)
  end

  @spec allocate(module) :: :ok
  def allocate(module),
    do: Agonex.Client.allocate(module)

  @spec shutdown(module) :: :ok
  def shutdown(module),
    do: Agonex.Client.shutdown(module)

  @spec reserve(module, duration) :: :ok
  def reserve(module, seconds),
    do: Agonex.Client.reserve(module, seconds)

  @spec get_game_server(module) :: {:ok, Agonex.GameServer.t()}
  def get_game_server(module),
    do: Agonex.Client.get_game_server(module)

  @spec watch_game_server(module) :: :ok | {:error, GRPC.RPCError.t()}
  def watch_game_server(module),
    do: Agonex.Client.watch_game_server(module)

  @spec set_label(module, String.t(), String.t()) :: :ok | {:error, GRPC.RPCError.t()}
  def set_label(module, key, value),
    do: Agonex.Client.set_label(module, key, value)

  @spec set_annotation(module, String.t(), String.t()) :: :ok | {:error, GRPC.RPCError.t()}
  def set_annotation(module, key, value),
    do: Agonex.Client.set_annotation(module, key, value)
end

defmodule Agonex.Client do
  @moduledoc false

  use Connection
  require Logger
  alias Agonex.{Duration, Empty, KeyValue, SDK}

  def start_link(url, task_sup, opts \\ []),
    do: Connection.start_link(__MODULE__, {url, task_sup, opts})

  def allocate(conn),
    do: Connection.cast(conn, :allocate)

  def shutdown(conn),
    do: Connection.cast(conn, :shutdown)

  def reserve(conn, seconds),
    do: Connection.call(conn, {:reserve, seconds})

  def get_game_server(conn),
    do: Connection.call(conn, :game_server)

  def watch_game_server(conn),
    do: Connection.call(conn, {:watch_game_server, self()})

  def set_label(conn, key, value),
    do: Connection.call(conn, {:set_label, key, value})

  def set_annotation(conn, key, value),
    do: Connection.call(conn, {:set_annotation, key, value})

  def init({url, opts}) do
    health_interval = Keyword.get(opts, :health_interval, 5000)
    grpc_opts = Keyword.get(opts, :grpc_opts, [])

    state = %{
      url: url,
      channel: nil,
      health_stream: nil,
      health_interval: health_interval,
      grpc_opts: grpc_opts
    }

    {:connect, :init, state}
  end

  def connect(_, state) do
    with {:ok, channel} <- GRPC.Stub.connect(state.url, state.grpc_opts),
         {:ok, health_stream} <- SDK.Stub.health(channel),
         {:ok, _} <- SDK.Stub.ready(state.channel, Empty.new()) do
      state = %{
        state
        | channel: channel,
          health_stream: health_stream
      }

      send(self(), :health)

      {:ok, state}
    else
      {:error, _} ->
        {:backoff, 1000, state}
    end
  end

  def disconnect(reason, state) do
    case reason do
      {:error, :closed} ->
        Logger.error("Connection closed")

      _ ->
        :ok
    end

    GRPC.Stub.disconnect(state.channel)

    state = %{
      state
      | channel: nil,
        health_stream: nil
    }

    {:connect, :reconnect, state}
  end

  def handle_info(:health, state) do
    GRPC.Stub.send_request(state.health_stream, Empty.new())
    Process.send_after(self(), :health, state.health_interval)
    {:noreply, state}
  end

  def handle_cast(:allocate, state) do
    case SDK.Stub.allocate(state.channel, Empty.new()) do
      {:ok, _} ->
        {:noreply, state}

      {:error, %GRPC.RPCError{}} = error ->
        {:disconnect, error, error, state}
    end
  end

  def handle_cast(:shutdown, state) do
    case SDK.Stub.shutdown(state.channel, Empty.new()) do
      {:ok, _} ->
        {:noreply, state}

      {:error, %GRPC.RPCError{}} = error ->
        {:disconnect, error, error, state}
    end
  end

  def handle_cast({:reserve, seconds}, state) do
    case SDK.Stub.reserve(state.channel, Duration.new(seconds: seconds)) do
      {:ok, _} ->
        {:reply, :ok, state}

      {:error, %GRPC.RPCError{}} = error ->
        {:reply, error, state}
    end
  end

  def handle_call(_, _, %{channel: nil} = state) do
    {:reply, {:error, :closed}, state}
  end

  def handle_call(:game_server, _, state) do
    case SDK.Stub.get_game_server(state.channel, Empty.new()) do
      {:ok, game_server} ->
        {:reply, {:ok, game_server}, state}

      {:error, %GRPC.RPCError{}} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:watch_game_server, sub_pid}, _, state) do
    case SDK.Stub.watch_game_server(state.channel, Empty.new()) do
      {:error, %GRPC.RPCError{}} = error ->
        {:stop, error, state}

      stream ->
        Task.Supervisor.start_child(
          state.task_sup,
          Agonex.Watcher,
          :loop,
          [{stream, sub_pid}]
        )

        {:noreply, state}
    end
  end

  def handle_call({:set_label, key, value}, _, state) do
    case SDK.Stub.set_label(state.channel, KeyValue.new(key: key, value: value)) do
      {:ok, _} ->
        {:reply, :ok, state}

      {:error, %GRPC.RPCError{}} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:set_annotation, key, value}, _, state) do
    case SDK.Stub.set_annotation(state.channel, KeyValue.new(key: key, value: value)) do
      {:ok, _} ->
        {:reply, :ok, state}

      {:error, %GRPC.RPCError{}} = error ->
        {:reply, error, state}
    end
  end
end

defmodule Agonex.Watcher do
  @moduledoc false

  def loop({stream, sub_pid}) do
    with {:ok, game_server} <- GRPC.Stub.recv(stream) do
      send(sub_pid, {:game_server_change, game_server})
      loop({stream, sub_pid})
    end
  end
end
