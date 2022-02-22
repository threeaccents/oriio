defmodule Mahi.ChunkUploader.StateHandoff do
  use Mahi.DeltaCrdt

  def handoff(upload_id, state) do
    DeltaCrdt.put(@crdt, upload_id, state)
  end

  def pickup(upload_id) do
    case DeltaCrdt.get(@crdt, upload_id) do
      nil ->
        nil

      state ->
        DeltaCrdt.delete(@crdt, upload_id)
        state
    end
  end
end
