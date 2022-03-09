defmodule Oriio.Uploads.ChunkUploadMonitorSupervisor do
  @moduledoc """
  Manages the supervisor lifecycle for ChunkUploadMonitor
  """

  use Supervisor

  alias Oriio.Uploads.ChunkUploadMonitorRegistry

  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: via_tuple(ChunkUploadMonitor))
  end

  @impl true
  def init(_opts) do
    children = [
      Oriio.Uploads.ChunkUploadMonitor,
    ]

    Supervisor.init(children, strategy: :one_for_one)
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
