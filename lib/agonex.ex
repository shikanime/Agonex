defmodule Agonex do
  use Connection
  require Logger
  alias Agonex.{Duration, Empty, KeyValue}
  alias Agonex.SDK.Stub

  def start_link(url, opts \\ []) do
    Connection.start_link(__MODULE__, {url, opts})
  end

  def ready(conn) do
    Connection.cast(conn, :ready)
  end

  def allocate(conn) do
    Connection.cast(conn, :allocate)
  end

  def shutdown(conn) do
    Connection.cast(conn, :shutdown)
  end

  def reserve(conn, seconds) do
    Connection.call(conn, {:reserve, seconds})
  end

  def get_game_server(conn) do
    Connection.call(conn, :game_server)
  end

  def watch_game_server(conn) do
    Connection.call(conn, :watch_game_server)
  end

  def set_label(conn, key, value) do
    Connection.call(conn, {:set_label, key, value})
  end

  def set_annotation(conn, key, value) do
    Connection.call(conn, {:set_annotation, key, value})
  end

  def init({url, opts}) do
    health_interval = Keyword.pop(opts, :health_interval, 5000)
    grpc_opts = Keyword.pop(opts, :grpc_opts, [])

    state = %{
      url: url,
      channel: nil,
      health: nil,
      health_interval: health_interval,
      grpc_opts: grpc_opts
    }

    {:connect, :init, state}
  end

  def connect(_, state) do
    with {:ok, channel} <- GRPC.Stub.connect(state.url, state.opts),
         {:ok, stream} <- connect_health(state.channel) do
      {:ok, %{state | channel: channel, health: stream}}
    else
      {:error, _} -> {:backoff, 1000, state}
    end
  end

  def disconnect(info, %{channel: channel} = state) do
    {:ok, _} = GRPC.Stub.disconnect(channel)

    case info do
      {:error, :closed} ->
        Logger.error("Connection closed")
    end

    {:connect, :reconnect, %{state | channel: nil}}
  end

  def handle_info(:health, _, state) do
    GRPC.Stub.send_request(state.health, Empty.new())
    Process.send_after(self(), :health, state.health_interval)
    {:noreply, state}
  end

  def handle_cast(:ready, _, state) do
    case Stub.ready(state.channel, Empty.new()) do
      {:ok, _} -> {:noreply, state}
      {:error, %GRPC.RPCError{}} = error -> {:disconnect, error, error, state}
    end
  end

  def handle_cast(:allocate, _, state) do
    case Stub.allocate(state.channel, Empty.new()) do
      {:ok, _} -> {:noreply, state}
      {:error, %GRPC.RPCError{}} = error -> {:disconnect, error, error, state}
    end
  end

  def handle_cast(:shutdown, _, state) do
    case Stub.shutdown(state.channel, Empty.new()) do
      {:ok, _} -> {:noreply, state}
      {:error, %GRPC.RPCError{}} = error -> {:disconnect, error, error, state}
    end
  end

  def handle_cast({:reserve, seconds}, _, state) do
    case Stub.reserve(state.channel, Duration.new(seconds: seconds)) do
      {:ok, _} -> {:reply, :ok, state}
      {:error, %GRPC.RPCError{}} = error -> {:disconnect, error, error, state}
    end
  end

  def handle_call(_, _, %{channel: nil} = state) do
    {:reply, {:error, :closed}, state}
  end

  def handle_call(:game_server, _, state) do
    case Stub.get_game_server(state.channel, Empty.new()) do
      {:ok, game_server} -> {:reply, {:ok, game_server}, state}
      {:error, %GRPC.RPCError{}} = error -> {:disconnect, error, error, state}
    end
  end

  def handle_call(:watch_game_server, _, state) do
    case Stub.watch_game_server(state.channel, Empty.new()) do
      {:error, %GRPC.RPCError{}} = error ->
        {:disconnect, error, error, state}

      stream ->
        {:reply, {:ok, stream |> grpc_to_stream()}, state}
    end
  end

  def handle_call({:set_label, key, value}, _, state) do
    case Stub.set_label(state.channel, KeyValue.new(key: key, value: value)) do
      {:ok, _} -> {:reply, :ok, state}
      {:error, %GRPC.RPCError{}} = error -> {:disconnect, error, error, state}
    end
  end

  def handle_call({:set_annotation, key, value}, _, state) do
    case Stub.set_annotation(state.channel, KeyValue.new(key: key, value: value)) do
      {:ok, _} -> {:reply, :ok, state}
      {:error, %GRPC.RPCError{}} = error -> {:disconnect, error, error, state}
    end
  end

  defp connect_health(channel) do
    case Stub.health(channel) do
      {:error, %GRPC.RPCError{}} = error ->
        error

      stream ->
        send(self(), :health)
        {:ok, stream}
    end
  end

  defp grpc_to_stream(stream) do
    Stream.resource(
      fn -> stream end,
      &GRPC.Stub.recv(&1),
      &GRPC.Stub.send_request(&1, Empty.new(), end_stream: true)
    )
  end
end
