defmodule Agonex do
  @moduledoc """
  The SDKs are relatively thin wrappers around gRPC generated clients.

  They connect to a small process that Agones coordinates to run alongside the
  Game Server in a Kubernetes Pod. This means that more languages can be
  supported in the future with minimal effort.

  There is also local development tooling for working against the SDK locally,
  without having to spin up an entire Kubernetes infrastructure.

  Calling any of state changing functions mentioned below does not guarantee
  that GameServer Custom Resource object would actually change its state right
  after the call. For instance, it could be moved to the Shutdown state
  elsewhere (for example, when a fleet scales down), which leads to no changes
  in GameServer object. You can verify the result of this call by waiting for
  the desired state in a callback to watch_game_server() function.
  """

  @type duration :: non_neg_integer

  @doc """
  With some matchmakers and game matching strategies, it can be important for
  game servers to mark themselves as Allocated. For those scenarios, this SDK
  functionality exists.

  There is a chance that GameServer does not actually become Allocated after
  this call. Please refer to the general note in Function Reference above.
  """
  @spec allocate :: :ok
  def allocate,
    do: Agonex.Client.allocate()

  @doc """
  This tells Agones that the Game Server is ready to take player connections.
  Once a Game Server has specified that it is Ready, then the Kubernetes
  GameServer record will be moved to the Ready state, and the details for its
  public address and connection port will be populated.

  While Agones prefers that shutdown() is run once a game has completed to
  delete the GameServer instance, if you want or need to move an Allocated
  GameServer back to Ready to be reused, you can call this SDK method again to
  do this.
  """
  @spec ready :: :ok
  def ready,
    do: Agonex.Client.ready()

  @doc """
  This tells Agones to shut down the currently running game server. The
  GameServer state will be set Shutdown and the backing Pod will be deleted, if
  they have not shut themselves down already.
  """
  @spec shutdown :: :ok
  def shutdown,
    do: Agonex.Client.shutdown()

  @doc """
  With some matchmaking scenarios and systems it is important to be able to
  ensure that a GameServer is unable to be deleted, but doesn’t trigger a
  FleetAutoscaler scale up. This is where reserve(seconds) is useful.

  reserve(seconds) will move the GameServer into the Reserved state for the
  specified number of seconds (0 is forever), and then it will be moved back to
  Ready state. While in Reserved state, the GameServer will not be deleted on
  scale down or Fleet update, and also it could not be Allocated using
  GameServerAllocation.

  This is often used when a game server process must register itself with an
  external system, such as a matchmaker, that requires it to designate itself as
  available for a game session for a certain period. Once a game session has
  started, it should call allocate() to designate that players are currently
  active on it.

  Calling other state changing SDK commands such as ready or allocate will turn
  off the timer to reset the GameServer back to the Ready state or to promote it
  to an Allocated state accordingly.
  """
  @spec reserve(duration) :: :ok
  def reserve(seconds) when is_integer(seconds),
    do: Agonex.Client.reserve(seconds)

  @doc """
  This returns most of the backing GameServer configuration and Status. This can
  be useful for instances where you may want to know Health check configuration,
  or the IP and Port the GameServer is currently allocated to.

  The easiest way to see what is exposed, is to check the sdk.proto ,
  specifically at the message GameServer.
  """
  @spec get_game_server :: {:ok, Agones.Dev.Sdk.GameServer.t()}
  def get_game_server,
    do: Agonex.Client.get_game_server()

  @doc """
  This executes the passed in callback with the current GameServer details
  whenever the underlying GameServer configuration is updated. This can be
  useful to track GameServer > Status > State changes, metadata changes, such as
  labels and annotations, and more.

  In combination with this SDK, manipulating Annotations and Labels can also be
  a useful way to communicate information through to running game server
  processes from outside those processes. This is especially useful when
  combined with GameServerAllocation applied metadata.

  The easiest way to see what is exposed, is to check the sdk.proto ,
  specifically at the message GameServer.
"""
  @spec watch_game_server :: :ok | {:error, GRPC.RPCError.t()}
  def watch_game_server,
    do: Agonex.Client.watch_game_server()

  @doc """
  This will set a Label value on the backing GameServer record that is stored in
  Kubernetes. To maintain isolation, the key value is automatically prefixed
  with “agones.dev/sdk-”.

  This can be useful if you want information from your running game server
  process to be observable or searchable through the Kubernetes API.
  """
  @spec set_label(String.t(), String.t()) :: :ok | {:error, GRPC.RPCError.t()}
  def set_label(key, value) when is_binary(key) and is_binary(value),
    do: Agonex.Client.set_label(key, value)

  @doc """
  This will set a Annotation value on the backing Gameserver record that is
  stored in Kubernetes. To maintain isolation, the key value is automatically
  prefixed with “agones.dev/sdk-”.

  This can be useful if you want information from your running game server
  process to be observable through the Kubernetes API.
"""
  @spec set_annotation(String.t(), String.t()) :: :ok | {:error, GRPC.RPCError.t()}
  def set_annotation(key, value) when is_binary(key) and is_binary(value),
    do: Agonex.Client.set_annotation(key, value)
end
