defmodule Agonex.Watcher do
  use GenServer

  def start_link(channel, pid) do
    GenServer.start_link(__MODULE__, :init, [{channel, pid}])
  end

  def init({channel, pid}) do
    state = %{
      channel: channel,
      stream: nil,
      pid: pid
    }

    {:ok, state, {:continue, :connect}}
  end

  def handle_continue(:connect, state) do
    case SDK.Stub.watch_game_server(state.channel, Empty.new()) do
      {:error, %GRPC.RPCError{}} = error ->
        {:stop, error, state}

      stream ->
        {:noreply, %{state | stream: stream}}
    end
  end

  def handle_info(:watch, state) do
    case GRPC.Stub.recv(state.stream) do
      {:ok, game_server} ->
        send(self(), :watch)
        send(state.pid, {:game_server_change, game_server})
        {:noreply, state}

      {:error, _} = error ->
        {:stop, error, state}
    end
  end

  def terminate(_, state) do
    GRPC.Stub.end_stream(state.stream)
  end
end
