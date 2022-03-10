defmodule Oriio.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Oriio.Uploads.{
    UploadMonitorSupervisor,
    UploadMonitorRegistry,
    UploadMonitor,
    ChunkUploadStateHandoff,
    ChunkUploadRegistry,
    ChunkUploadSupervisor,
    SignedUploadStateHandoff,
    SignedUploadRegistry,
    SignedUploadSupervisor
  }

  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies) || topologies()

    children = [
      # Start the PubSub system
      {Phoenix.PubSub, name: Oriio.PubSub},
      # Clustering
      {Cluster.Supervisor, [topologies, [name: Oriio.ClusterSupervisor]]},
      # Chunk Uploads
      ChunkUploadStateHandoff,
      ChunkUploadRegistry,
      ChunkUploadSupervisor,
      UploadMonitorRegistry,
      UploadMonitorSupervisor,
      %{
        id: :upload_monitor_cluster_connector,
        restart: :transient,
        start: {Task, :start_link, [&start_upload_monitor/0]}
      },
      # Signed Uploads
      SignedUploadStateHandoff,
      SignedUploadRegistry,
      SignedUploadSupervisor
      # Start a worker by calling: Oriio.Worker.start_link(arg)
      # {Oriio.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Oriio.Supervisor)
  end

  defp start_upload_monitor do
    Horde.DynamicSupervisor.start_child(UploadMonitorSupervisor, UploadMonitor)
  end

  defp topologies do
    [
      oriio: [
        strategy: Cluster.Strategy.Gossip
      ]
    ]
  end
end
