defmodule Agonex do
  @moduledoc """
  A SDK client for Agones.
  """

  use Connection
  require Logger
  alias Agonex.{Duration, Empty, KeyValue, SDK, Watcher}

  @type conn :: atom | pid | {atom, any} | {:via, atom, any}
  @type duration :: non_neg_integer

  def start_link(url, opts \\ []),
    do: Connection.start_link(__MODULE__, {url, opts})

  @spec allocate(conn) :: :ok
  def allocate(conn),
    do: Connection.cast(conn, :allocate)

  @spec shutdown(conn) :: :ok
  def shutdown(conn),
    do: Connection.cast(conn, :shutdown)

  @spec reserve(conn, duration) :: :ok
  def reserve(conn, seconds),
    do: Connection.call(conn, {:reserve, seconds})

  @spec get_game_server(conn) :: {:ok, Agonex.GameServer.t()}
  def get_game_server(conn),
    do: Connection.call(conn, :game_server)

  @spec watch_game_server(conn) :: :ok | {:error, GRPC.RPCError.t()}
  def watch_game_server(conn),
    do: Connection.call(conn, :watch_game_server)

  @spec set_label(conn, String.t(), String.t()) :: :ok | {:error, GRPC.RPCError.t()}
  def set_label(conn, key, value),
    do: Connection.call(conn, {:set_label, key, value})

  @spec set_annotation(conn, String.t(), String.t()) :: :ok | {:error, GRPC.RPCError.t()}
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

    Process.flag(:trap_exit, true)

    {:connect, :init, state}
  end

  def connect(_, state) do
    with {:ok, channel} <- GRPC.Stub.connect(state.url, state.grpc_opts),
         {:ok, health_stream} <- SDK.Stub.health(channel),
         {:ok, _}<- SDK.Stub.ready(state.channel, Empty.new()) do
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

  def handle_call(:watch_game_server, {pid, _}, state) do
    case Watcher.start_link(state.channel, pid) do
      {:ok, _} ->
        {:reply, :ok, state}

      {:error, _} = error ->
        {:reply, error, state}
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
