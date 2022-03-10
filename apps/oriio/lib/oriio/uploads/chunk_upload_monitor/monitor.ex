defmodule Oriio.Uploads.UploadMonitor do
  @moduledoc """
  Monitor for chunked and signed uploads.
  It checks for stale uploads and kills them to avoid process leaks.
  """
  use GenServer

  require Logger

  alias Oriio.Uploads.{
    ChunkUploadMonitorRegistry,
    ChunkUploadRegistry,
    ChunkUploadWorker,
  }

  @thirty_minutes 30 * 60 * 1000
  @valid_hours 5

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_) do
    case GenServer.start_link(__MODULE__, [], name: via_tuple(ChunkUploadMonitor)) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info("already started at #{inspect(pid)}, returning :ignore")
        :ignore
    end
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
    DateTime.diff(expiry_time, DateTime.utc_now()) <= 0
  end

  def whereis(name \\ ChunkUploadMonitor) do
    name
    |> via_tuple()
    |> GenServer.whereis()
  end

  defp via_tuple(name) do
    {:via, Horde.Registry, {ChunkUploadMonitorRegistry, name}}
  end
end
