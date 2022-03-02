defmodule Mahi.Uploads.ChunkUploadMonitor do
  @moduledoc """
  This module will check for stale uploads that maybe the client got disconnected for 5 hours and sent no more chunks to avoid process leaks.
  It will also check for chunks that have been merged and for some reason the process wasn't killed.
  """
  use GenServer

  alias Mahi.Uploads.ChunkUploadRegistry
  alias Mahi.Uploads.ChunkUploadWorker

  @thirty_minutes 30 * 60 * 1000
  @valid_hours 5

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    schedule_work()

    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    check_for_stale_uploads()

    schedule_work()

    {:noreply, state}
  end

  defp schedule_work do
    Process.send_after(self(), :work, @thirty_minutes)
  end

  defp check_for_stale_uploads do
    pids = list_chunk_upload_processes()
    for pid <- pids, is_upload_stale?(pid), do: Process.exit(pid, :normal)
  end

  defp list_chunk_upload_processes do
    Horde.Registry.select(ChunkUploadRegistry, [
      {{:"$1", :"$2", :"$3"}, [], [:"$2"]}
    ])
  end

  defp is_upload_stale?(pid) do
    updated_at = ChunkUploadWorker.updated_at(pid)
    expiry_time = DateTime.add(updated_at, @valid_hours * 60, :second)
    DateTime.diff(expiry_time, DateTime.utc_now()) < 0
  end
end
