defmodule Agonex.Watcher do
  def start_link(stream, consumer) do
    :proc_lib.start_link(__MODULE__, :init, [{stream, consumer}])
  end

  def init({stream, consumer}) do
    :ok = :proc_lib.init_ack({:ok, self()})
    loop(%{stream: stream, consumer: consumer})
  end

  defp loop(state) do
    case GRPC.Stub.recv(state.stream) do
      {:ok, game_server} ->
        send(state.consumer, {:game_server_change, game_server})
        loop(state)

      {:error, _} = error ->
        exit({:shutdown, error})
    end
  end
end
