defmodule Mahi.ChunkUploader.StateHandoff do
  use Mahi.DeltaCrdt

  def handoff(upload_id, state) do
    DeltaCrdt.put(@crdt, upload_id, state)
  end

  def pickup(upload_id) do
    state = DeltaCrdt.get(@crdt, upload_id)

    # delete state if exists
    DeltaCrdt.delete(@crdt, upload_id)

    state
  end
end
