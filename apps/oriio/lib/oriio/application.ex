defmodule Oriio.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies) || topologies()

    children = [
      # Start the PubSub system
      {Phoenix.PubSub, name: Oriio.PubSub},
      # Clustering
      {Cluster.Supervisor, [topologies, [name: Oriio.ClusterSupervisor]]},
      # Chunk Uploads
      Oriio.Uploads.StateHandoffSupervisor,
      Oriio.Uploads.ChunkUploadRegistry,
      Oriio.Uploads.ChunkUploadSupervisor,
      Oriio.Uploads.ChunkUploadMonitorSupervisor,
      # Start a worker by calling: Oriio.Worker.start_link(arg)
      # {Oriio.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Oriio.Supervisor)
  end

  defp topologies do
    [
      oriio: [
        strategy: Cluster.Strategy.Gossip
      ]
    ]
  end
end
