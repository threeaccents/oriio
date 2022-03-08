defmodule Oriio.Uploads.SignedUploadStateHandoff do
  use Oriio.DeltaCrdt

  alias Oriio.Uploads.SignedUploadWorker

  @type signed_upload_id() :: binary()
  @type signed_upload_state() :: SignedUploadWorker.state()

  @spec handoff(signed_upload_id(), signed_upload_state()) :: DeltaCrdt.t()
  def handoff(signed_upload_id, state) do
    DeltaCrdt.put(@crdt, signed_upload_id, state)
  end

  @spec pickup(signed_upload_id()) :: signed_upload_state() | nil
  def pickup(signed_upload_id) do
    case DeltaCrdt.get(@crdt, signed_upload_id) do
      nil ->
        nil

      signed_upload_state ->
        DeltaCrdt.delete(@crdt, signed_upload_id)
        signed_upload_state
    end
  end
end
