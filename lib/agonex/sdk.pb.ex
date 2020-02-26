defmodule Agonex.Empty do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{}
  defstruct []
end

defmodule Agonex.KeyValue do
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

defmodule Agonex.Duration do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          seconds: integer
        }
  defstruct [:seconds]

  field(:seconds, 1, type: :int64)
end

defmodule Agonex.GameServer do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          object_meta: Agonex.GameServer.ObjectMeta.t() | nil,
          spec: Agonex.GameServer.Spec.t() | nil,
          status: Agonex.GameServer.Status.t() | nil
        }
  defstruct [:object_meta, :spec, :status]

  field(:object_meta, 1, type: Agonex.GameServer.ObjectMeta)
  field(:spec, 2, type: Agonex.GameServer.Spec)
  field(:status, 3, type: Agonex.GameServer.Status)
end

defmodule Agonex.GameServer.ObjectMeta do
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
    type: Agonex.GameServer.ObjectMeta.AnnotationsEntry,
    map: true
  )

  field(:labels, 9, repeated: true, type: Agonex.GameServer.ObjectMeta.LabelsEntry, map: true)
end

defmodule Agonex.GameServer.ObjectMeta.AnnotationsEntry do
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

defmodule Agonex.GameServer.ObjectMeta.LabelsEntry do
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

defmodule Agonex.GameServer.Spec do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          health: Agonex.GameServer.Spec.Health.t() | nil
        }
  defstruct [:health]

  field(:health, 1, type: Agonex.GameServer.Spec.Health)
end

defmodule Agonex.GameServer.Spec.Health do
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

defmodule Agonex.GameServer.Status do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          state: String.t(),
          address: String.t(),
          ports: [Agonex.GameServer.Status.Port.t()]
        }
  defstruct [:state, :address, :ports]

  field(:state, 1, type: :string)
  field(:address, 2, type: :string)
  field(:ports, 3, repeated: true, type: Agonex.GameServer.Status.Port)
end

defmodule Agonex.GameServer.Status.Port do
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

defmodule Agonex.SDK.Service do
  @moduledoc false
  use GRPC.Service, name: "agonex.SDK"

  rpc(:Ready, Agonex.Empty, Agonex.Empty)
  rpc(:Allocate, Agonex.Empty, Agonex.Empty)
  rpc(:Shutdown, Agonex.Empty, Agonex.Empty)
  rpc(:Health, stream(Agonex.Empty), Agonex.Empty)
  rpc(:GetGameServer, Agonex.Empty, Agonex.GameServer)
  rpc(:WatchGameServer, Agonex.Empty, stream(Agonex.GameServer))
  rpc(:SetLabel, Agonex.KeyValue, Agonex.Empty)
  rpc(:SetAnnotation, Agonex.KeyValue, Agonex.Empty)
  rpc(:Reserve, Agonex.Duration, Agonex.Empty)
end

defmodule Agonex.SDK.Stub do
  @moduledoc false
  use GRPC.Stub, service: Agonex.SDK.Service
end
