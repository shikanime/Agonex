defmodule Agonex.Client do
  @moduledoc false

  @default_health_interval 50000

  use GenServer
  require Logger
  alias Agones.Dev.Sdk.{Duration, Empty, KeyValue, SDK.Stub}

  def start_link(options) do
    {sup_opts, opts} = Keyword.split(options, [:name])
    GenServer.start_link(__MODULE__, opts, sup_opts)
  end

  def allocate,
    do: GenServer.call(__MODULE__, :allocate)

  def ready,
    do: GenServer.call(__MODULE__, :ready)

  def shutdown,
    do: GenServer.call(__MODULE__, :shutdown)

  def reserve(seconds),
    do: GenServer.call(__MODULE__, {:reserve, seconds})

  def get_game_server,
    do: GenServer.call(__MODULE__, :game_server)

  def watch_game_server,
    do: GenServer.call(__MODULE__, {:watch_game_server, self()})

  def set_label(key, value),
    do: GenServer.call(__MODULE__, {:set_label, key, value})

  def set_annotation(key, value),
    do: GenServer.call(__MODULE__, {:set_annotation, key, value})

  def init(options) do
    unless watcher_sup = Keyword.fetch!(options, :watcher_supervisor) do
      raise ArgumentError, "expected :watcher_supervisor option to be given"
    end

    port = System.get_env("AGONES_SDK_GRPC_PORT", "9357") |> String.to_integer()

    health_interval = Keyword.get(options, :health_interval, @default_health_interval)
    grpc_opts = Keyword.get(options, :grpc_options, [])

    state = %{
      watcher_sup: watcher_sup,
      channel: nil,
      health_stream: nil,
      health_interval: health_interval
    }

    {:ok, state, {:continue, {:connect, port, grpc_opts}}}
  end

  def handle_continue({:connect, port, opts}, state) do
    stub_opts = Keyword.merge(opts, adapter_opts: %{http2_opts: %{keepalive: :infinity}})

    case GRPC.Stub.connect("localhost", port, stub_opts) do
      {:ok, channel} ->
        health_stream = Stub.health(channel)

        state = %{
          state
          | channel: channel,
            health_stream: health_stream
        }

        send(self(), :health)

        {:noreply, state}

      {:error, "Error when opening connection: protocol " <> proto} ->
        {:stop, {:error, {:protocol_mismatch, proto |> String.to_existing_atom()}}, state}

      {:error, "Error when opening connection: :" <> reason} ->
        {:stop, {:error, reason |> String.to_existing_atom()}, state}
    end
  end

  def handle_info(:health, state) do
    GRPC.Stub.send_request(state.health_stream, Empty.new())
    Process.send_after(self(), :health, state.health_interval)
    {:noreply, state}
  end

  def handle_call(_, _, %{channel: nil} = state) do
    {:reply, {:error, :closed}, state}
  end

  def handle_call(:ready, _, state) do
    case Stub.ready(state.channel, Empty.new()) do
      {:ok, _} ->
        {:reply, :ok, state}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  def handle_call(:allocate, _, state) do
    case Stub.allocate(state.channel, Empty.new()) do
      {:ok, _} ->
        {:reply, :ok, state}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  def handle_call(:shutdown, _, state) do
    case Stub.shutdown(state.channel, Empty.new()) do
      {:ok, _} ->
        {:reply, :ok, state}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:reserve, seconds}, _, state) do
    case Stub.reserve(state.channel, seconds_to_duration(seconds)) do
      {:ok, _} ->
        {:reply, :ok, state}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  def handle_call(:game_server, _, state) do
    case Stub.get_game_server(state.channel, Empty.new()) do
      {:ok, game_server} ->
        {:reply, {:ok, game_server}, state}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:watch_game_server, consumer}, _, state) do
    DynamicSupervisor.start_child(state.watcher_sup, {Agonex.Watcher, [consumer, state.channel]})
    {:reply, :ok, state}
  end

  def handle_call({:set_label, key, value}, _, state) do
    case Stub.set_label(state.channel, KeyValue.new(key: key, value: value)) do
      {:ok, _} ->
        {:reply, :ok, state}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:set_annotation, key, value}, _, state) do
    case Stub.set_annotation(state.channel, KeyValue.new(key: key, value: value)) do
      {:ok, _} ->
        {:reply, :ok, state}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  defp seconds_to_duration(:infinity),
    do: Duration.new(seconds: 0)

  defp seconds_to_duration(seconds),
    do: Duration.new(seconds: seconds)
end

defmodule Agonex.Watcher do
  @moduledoc false
  use GenServer
  alias Agones.Dev.Sdk.{Empty, SDK.Stub}

  def start_link(consumer, channel, opts \\ []),
    do: GenServer.start_link(__MODULE__, {consumer, channel}, opts)

  def init({consumer, channel}) do
    send(self(), :recv)
    {:ok, %{channel: channel, consumer: consumer}}
  end

  def handle_info(:recv, state) do
    case Stub.watch_game_server(state.channel, Empty.new()) do
      {:ok, stream} ->
        Enum.each(stream, fn
          {:ok, game_server} ->
            send(state.consumer, {:game_server_change, game_server})
            send(self(), :recv)
            {:noreply, state}

          {:error, _} ->
            {:stop, {:error, :grpc_err}, state}
        end)

      {:error, _} ->
        {:stop, {:error, :grpc_err}, state}
    end
  end
end
