defmodule Mahi.Uploads.ChunkUploadMonitor do
  @moduledoc """
  This module will check for stale uploads that maybe the client got disconnected for 5 hours and sent no more chunks to avoid process leaks.
  It will also check for chunks that have been merged and for some reason the process wasn't killed.
  """
  use GenServer
  use Horde.Registry

  alias Mahi.Uploads.ChunkUploadRegistry

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
    uploads = list_chunk_upload_processes()
    Enum.each(uploads, &maybe_terminate_upload_process/1)
  end

  defp list_chunk_upload_processes do
    Horde.Registry.select(ChunkUploadRegistry, [
      {{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}
    ])
  end

  defp is_upload_stale?(updated_at) do
    valid_time = DateTime.utc_now() |> DateTime.add(-@valid_hours * 60 * 60, :second)
    DateTime.diff(valid_time, updated_at) < 0
  end

  defp maybe_terminate_upload_process({_, pid, %{update_at: updated_at}}) do
    if is_upload_stale?(updated_at), do: Process.exit(pid, :normal)
  end
end
