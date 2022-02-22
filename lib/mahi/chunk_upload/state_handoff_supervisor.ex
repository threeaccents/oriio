defmodule Mahi.ChunkUpload.StateHandoff.Supervisor do
  use Supervisor

  @crdt_name Mahi.ChunkUpload.StateHandoff.Crdt

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    crdt_opts = [name: @crdt_name, crdt: DeltaCrdt.AWLWWMap]

    children = [
      {DeltaCrdt, crdt_opts},
      {Horde.NodeListener, Mahi.ChunkUpload.StateHandoff},
      Mahi.ChunkUpload.StateHandoff
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
