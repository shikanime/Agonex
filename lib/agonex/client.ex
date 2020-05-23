defmodule Agonex.Client do
  @moduledoc false

  use Connection
  require Logger
  alias Agones.Dev.Sdk.{Duration, Empty, KeyValue, SDK.Stub}

  def start_link(options) do
    Connection.start_link(__MODULE__, options, name: __MODULE__)
  end

  def allocate,
    do: Connection.cast(__MODULE__, :allocate)

  def ready,
    do: Connection.cast(__MODULE__, :ready)

  def shutdown,
    do: Connection.cast(__MODULE__, :shutdown)

  def reserve(seconds),
    do: Connection.cast(__MODULE__, {:reserve, seconds})

  def get_game_server,
    do: Connection.call(__MODULE__, :game_server)

  def watch_game_server,
    do: Connection.call(__MODULE__, {:watch_game_server, self()})

  def set_label(key, value),
    do: Connection.call(__MODULE__, {:set_label, key, value})

  def set_annotation(key, value),
    do: Connection.call(__MODULE__, {:set_annotation, key, value})

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker
    }
  end

  def init(options) do
    host = Keyword.fetch!(options, :host)
    port = Keyword.fetch!(options, :port)
    health_interval = Keyword.fetch!(options, :health_interval)
    grpc_opts = Keyword.fetch!(options, :grpc_opts)

    state = %{
      host: host,
      port: port,
      channel: nil,
      health_stream: nil,
      health_interval: health_interval,
      grpc_opts: grpc_opts
    }

    {:connect, :init, state}
  end

  def connect(_, state) do
    case GRPC.Stub.connect(state.host, state.port, state.grpc_opts) do
      {:ok, channel} ->
        health_stream = Stub.health(channel)

        state = %{
          state
          | channel: channel,
            health_stream: health_stream
        }

        send(self(), :health)

        {:ok, state}

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

  def handle_cast(:ready, state) do
    case Stub.ready(state.channel, Empty.new()) do
      {:ok, _} ->
        {:noreply, state}

      {:error, %GRPC.RPCError{}} = error ->
        {:disconnect, error, error, state}
    end
  end

  def handle_cast(:allocate, state) do
    case Stub.allocate(state.channel, Empty.new()) do
      {:ok, _} ->
        {:noreply, state}

      {:error, %GRPC.RPCError{}} = error ->
        {:disconnect, error, error, state}
    end
  end

  def handle_cast(:shutdown, state) do
    case Stub.shutdown(state.channel, Empty.new()) do
      {:ok, _} ->
        {:noreply, state}

      {:error, %GRPC.RPCError{}} = error ->
        {:disconnect, error, error, state}
    end
  end

  def handle_cast({:reserve, seconds}, state) do
    case Stub.reserve(state.channel, Duration.new(seconds: seconds)) do
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
    case Stub.get_game_server(state.channel, Empty.new()) do
      {:ok, game_server} ->
        {:reply, {:ok, game_server}, state}

      {:error, %GRPC.RPCError{}} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:watch_game_server, sub_pid}, _, state) do
    case Stub.watch_game_server(state.channel, Empty.new()) do
      {:error, %GRPC.RPCError{}} = error ->
        {:stop, error, state}

      stream ->
        Task.Supervisor.start_child(
          Agonex.TaskSupervisor,
          Agonex.Watcher,
          :loop,
          [{stream, sub_pid}]
        )

        {:noreply, state}
    end
  end

  def handle_call({:set_label, key, value}, _, state) do
    case Stub.set_label(state.channel, KeyValue.new(key: key, value: value)) do
      {:ok, _} ->
        {:reply, :ok, state}

      {:error, %GRPC.RPCError{}} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:set_annotation, key, value}, _, state) do
    case Stub.set_annotation(state.channel, KeyValue.new(key: key, value: value)) do
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
