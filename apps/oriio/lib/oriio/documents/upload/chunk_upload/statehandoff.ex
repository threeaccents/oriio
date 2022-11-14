defmodule Oriio.Uploads.UploadStateHandoff do
  @moduledoc """
  Handles state handoff between processes. It uses DeltaCRDT to manage the distributed state syncronization.
  """

  use Oriio.DeltaCrdt

  alias Oriio.Uploads.UploadWorker

  @type upload_id() :: binary()
  @type upload_state() :: UploadWorker.state()

  @spec handoff(upload_id(), upload_state()) :: DeltaCrdt.t()
  def handoff(upload_id, state) do
    DeltaCrdt.put(@crdt, upload_id, state)
  end

  @spec pickup(upload_id()) :: upload_state() | nil
  def pickup(upload_id) do
    case DeltaCrdt.get(@crdt, upload_id) do
      nil ->
        nil

      upload_state ->
        DeltaCrdt.delete(@crdt, upload_id)
        upload_state
    end
  end
end
