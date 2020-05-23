defmodule Agones.Dev.Sdk.Empty do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{}
  defstruct []
end

defmodule Agones.Dev.Sdk.KeyValue do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t()
        }
  defstruct [:key, :value]

  field :key, 1, type: :string
  field :value, 2, type: :string
end

defmodule Agones.Dev.Sdk.Duration do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          seconds: integer
        }
  defstruct [:seconds]

  field :seconds, 1, type: :int64
end

defmodule Agones.Dev.Sdk.GameServer do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          object_meta: Agones.Dev.Sdk.GameServer.ObjectMeta.t() | nil,
          spec: Agones.Dev.Sdk.GameServer.Spec.t() | nil,
          status: Agones.Dev.Sdk.GameServer.Status.t() | nil
        }
  defstruct [:object_meta, :spec, :status]

  field :object_meta, 1, type: Agones.Dev.Sdk.GameServer.ObjectMeta
  field :spec, 2, type: Agones.Dev.Sdk.GameServer.Spec
  field :status, 3, type: Agones.Dev.Sdk.GameServer.Status
end

defmodule Agones.Dev.Sdk.GameServer.ObjectMeta do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t(),
          namespace: String.t(),
          uid: String.t(),
          resource_version: String.t(),
          generation: integer,
          creation_timestamp: integer,
          deletion_timestamp: integer,
          annotations: %{String.t() => String.t()},
          labels: %{String.t() => String.t()}
        }
  defstruct [
    :name,
    :namespace,
    :uid,
    :resource_version,
    :generation,
    :creation_timestamp,
    :deletion_timestamp,
    :annotations,
    :labels
  ]

  field :name, 1, type: :string
  field :namespace, 2, type: :string
  field :uid, 3, type: :string
  field :resource_version, 4, type: :string
  field :generation, 5, type: :int64
  field :creation_timestamp, 6, type: :int64
  field :deletion_timestamp, 7, type: :int64

  field :annotations, 8,
    repeated: true,
    type: Agones.Dev.Sdk.GameServer.ObjectMeta.AnnotationsEntry,
    map: true

  field :labels, 9,
    repeated: true,
    type: Agones.Dev.Sdk.GameServer.ObjectMeta.LabelsEntry,
    map: true
end

defmodule Agones.Dev.Sdk.GameServer.ObjectMeta.AnnotationsEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t()
        }
  defstruct [:key, :value]

  field :key, 1, type: :string
  field :value, 2, type: :string
end

defmodule Agones.Dev.Sdk.GameServer.ObjectMeta.LabelsEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t()
        }
  defstruct [:key, :value]

  field :key, 1, type: :string
  field :value, 2, type: :string
end

defmodule Agones.Dev.Sdk.GameServer.Spec do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          health: Agones.Dev.Sdk.GameServer.Spec.Health.t() | nil
        }
  defstruct [:health]

  field :health, 1, type: Agones.Dev.Sdk.GameServer.Spec.Health
end

defmodule Agones.Dev.Sdk.GameServer.Spec.Health do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          disabled: boolean,
          period_seconds: integer,
          failure_threshold: integer,
          initial_delay_seconds: integer
        }
  defstruct [:disabled, :period_seconds, :failure_threshold, :initial_delay_seconds]

  field :disabled, 1, type: :bool
  field :period_seconds, 2, type: :int32
  field :failure_threshold, 3, type: :int32
  field :initial_delay_seconds, 4, type: :int32
end

defmodule Agones.Dev.Sdk.GameServer.Status do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          state: String.t(),
          address: String.t(),
          ports: [Agones.Dev.Sdk.GameServer.Status.Port.t()],
          players: Agones.Dev.Sdk.GameServer.Status.PlayerStatus.t() | nil
        }
  defstruct [:state, :address, :ports, :players]

  field :state, 1, type: :string
  field :address, 2, type: :string
  field :ports, 3, repeated: true, type: Agones.Dev.Sdk.GameServer.Status.Port
  field :players, 4, type: Agones.Dev.Sdk.GameServer.Status.PlayerStatus
end

defmodule Agones.Dev.Sdk.GameServer.Status.Port do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t(),
          port: integer
        }
  defstruct [:name, :port]

  field :name, 1, type: :string
  field :port, 2, type: :int32
end

defmodule Agones.Dev.Sdk.GameServer.Status.PlayerStatus do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          count: integer,
          capacity: integer,
          ids: [String.t()]
        }
  defstruct [:count, :capacity, :ids]

  field :count, 1, type: :int64
  field :capacity, 2, type: :int64
  field :ids, 3, repeated: true, type: :string
end

defmodule Agones.Dev.Sdk.SDK.Service do
  @moduledoc false
  use GRPC.Service, name: "agones.dev.sdk.SDK"

  rpc :Ready, Agones.Dev.Sdk.Empty, Agones.Dev.Sdk.Empty
  rpc :Allocate, Agones.Dev.Sdk.Empty, Agones.Dev.Sdk.Empty
  rpc :Shutdown, Agones.Dev.Sdk.Empty, Agones.Dev.Sdk.Empty
  rpc :Health, stream(Agones.Dev.Sdk.Empty), Agones.Dev.Sdk.Empty
  rpc :GetGameServer, Agones.Dev.Sdk.Empty, Agones.Dev.Sdk.GameServer
  rpc :WatchGameServer, Agones.Dev.Sdk.Empty, stream(Agones.Dev.Sdk.GameServer)
  rpc :SetLabel, Agones.Dev.Sdk.KeyValue, Agones.Dev.Sdk.Empty
  rpc :SetAnnotation, Agones.Dev.Sdk.KeyValue, Agones.Dev.Sdk.Empty
  rpc :Reserve, Agones.Dev.Sdk.Duration, Agones.Dev.Sdk.Empty
end

defmodule Agones.Dev.Sdk.SDK.Stub do
  @moduledoc false
  use GRPC.Stub, service: Agones.Dev.Sdk.SDK.Service
end
