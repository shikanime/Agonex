defmodule Agones.Empty do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{}
  defstruct []
end

defmodule Agones.KeyValue do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t()
        }
  defstruct [:key, :value]

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule Agones.Duration do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          seconds: integer
        }
  defstruct [:seconds]

  field(:seconds, 1, type: :int64)
end

defmodule Agones.GameServer do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          object_meta: Agones.GameServer.ObjectMeta.t() | nil,
          spec: Agones.GameServer.Spec.t() | nil,
          status: Agones.GameServer.Status.t() | nil
        }
  defstruct [:object_meta, :spec, :status]

  field(:object_meta, 1, type: Agones.GameServer.ObjectMeta)
  field(:spec, 2, type: Agones.GameServer.Spec)
  field(:status, 3, type: Agones.GameServer.Status)
end

defmodule Agones.GameServer.ObjectMeta do
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

  field(:name, 1, type: :string)
  field(:namespace, 2, type: :string)
  field(:uid, 3, type: :string)
  field(:resource_version, 4, type: :string)
  field(:generation, 5, type: :int64)
  field(:creation_timestamp, 6, type: :int64)
  field(:deletion_timestamp, 7, type: :int64)

  field(:annotations, 8,
    repeated: true,
    type: Agones.GameServer.ObjectMeta.AnnotationsEntry,
    map: true
  )

  field(:labels, 9, repeated: true, type: Agones.GameServer.ObjectMeta.LabelsEntry, map: true)
end

defmodule Agones.GameServer.ObjectMeta.AnnotationsEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t()
        }
  defstruct [:key, :value]

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule Agones.GameServer.ObjectMeta.LabelsEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t()
        }
  defstruct [:key, :value]

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule Agones.GameServer.Spec do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          health: Agones.GameServer.Spec.Health.t() | nil
        }
  defstruct [:health]

  field(:health, 1, type: Agones.GameServer.Spec.Health)
end

defmodule Agones.GameServer.Spec.Health do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          disabled: boolean,
          period_seconds: integer,
          failure_threshold: integer,
          initial_delay_seconds: integer
        }
  defstruct [:disabled, :period_seconds, :failure_threshold, :initial_delay_seconds]

  field(:disabled, 1, type: :bool)
  field(:period_seconds, 2, type: :int32)
  field(:failure_threshold, 3, type: :int32)
  field(:initial_delay_seconds, 4, type: :int32)
end

defmodule Agones.GameServer.Status do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          state: String.t(),
          address: String.t(),
          ports: [Agones.GameServer.Status.Port.t()]
        }
  defstruct [:state, :address, :ports]

  field(:state, 1, type: :string)
  field(:address, 2, type: :string)
  field(:ports, 3, repeated: true, type: Agones.GameServer.Status.Port)
end

defmodule Agones.GameServer.Status.Port do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t(),
          port: integer
        }
  defstruct [:name, :port]

  field(:name, 1, type: :string)
  field(:port, 2, type: :int32)
end

defmodule Agones.SDK.Service do
  @moduledoc false
  use GRPC.Service, name: "agones.SDK"

  rpc(:Ready, Agones.Empty, Agones.Empty)
  rpc(:Allocate, Agones.Empty, Agones.Empty)
  rpc(:Shutdown, Agones.Empty, Agones.Empty)
  rpc(:Health, stream(Agones.Empty), Agones.Empty)
  rpc(:GetGameServer, Agones.Empty, Agones.GameServer)
  rpc(:WatchGameServer, Agones.Empty, stream(Agones.GameServer))
  rpc(:SetLabel, Agones.KeyValue, Agones.Empty)
  rpc(:SetAnnotation, Agones.KeyValue, Agones.Empty)
  rpc(:Reserve, Agones.Duration, Agones.Empty)
end

defmodule Agones.SDK.Stub do
  @moduledoc false
  use GRPC.Stub, service: Agones.SDK.Service
end
