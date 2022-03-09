defmodule Oriio.Uploads.ChunkUploadMonitor do
  @moduledoc """
  This module will check for stale uploads that maybe the client got disconnected for 5 hours and sent no more chunks to avoid process leaks.
  It will also check for chunks that have been merged and for some reason the process wasn't killed.
  """
  use GenServer

  alias Oriio.Uploads.{
    ChunkUploadMonitorRegistry,
    ChunkUploadRegistry,
    ChunkUploadWorker,
    ChunkUploadMonitorSupervisor
  }

  @thirty_minutes 30 * 60 * 1000
  @valid_hours 5

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    :net_kernel.monitor_nodes(true, node_type: :visible)

    schedule_work()

    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    check_for_stale_uploads()

    schedule_work()

    {:noreply, state}
  end

  @impl true
  def handle_info({:nodeup, _node, _node_type}, state) do
    set_members(ChunkUploadMonitorRegistry)
    set_members(ChunkUploadMonitorSupervisor)

    {:noreply, state}
  end

  @impl true
  def handle_info({:nodedown, _node, _node_type}, state) do
    set_members(ChunkUploadMonitorRegistry)
    set_members(ChunkUploadMonitorSupervisor)

    {:noreply, state}
  end

  defp set_members(name) do
    members = Enum.map([Node.self() | Node.list()], &{name, &1})

    :ok = Horde.Cluster.set_members(name, members)
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
end
