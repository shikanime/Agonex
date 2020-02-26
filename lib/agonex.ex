defmodule Agonex do
  @moduledoc """
  A SDK client for Agones.
  """

  @type duration :: non_neg_integer

  @spec allocate :: :ok
  def allocate,
    do: Agonex.Client.allocate()

  @spec ready :: :ok
  def ready,
    do: Agonex.Client.ready()

  @spec shutdown :: :ok
  def shutdown,
    do: Agonex.Client.shutdown()

  @spec reserve(duration) :: :ok
  def reserve(seconds),
    do: Agonex.Client.reserve(seconds)

  @spec get_game_server :: {:ok, Agones.GameServer.t()}
  def get_game_server,
    do: Agonex.Client.get_game_server()

  @spec watch_game_server :: :ok | {:error, GRPC.RPCError.t()}
  def watch_game_server,
    do: Agonex.Client.watch_game_server()

  @spec set_label(String.t(), String.t()) :: :ok | {:error, GRPC.RPCError.t()}
  def set_label(key, value),
    do: Agonex.Client.set_label(key, value)

  @spec set_annotation(String.t(), String.t()) :: :ok | {:error, GRPC.RPCError.t()}
  def set_annotation(key, value),
    do: Agonex.Client.set_annotation(key, value)
end
