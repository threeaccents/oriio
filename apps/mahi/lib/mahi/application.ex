defmodule Mahi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies) || topologies()

    children = [
      # Start the PubSub system
      {Phoenix.PubSub, name: Mahi.PubSub},
      # Clustering
      {Cluster.Supervisor, [topologies, [name: Mahi.ClusterSupervisor]]},
      # Chunk Uploads
      Mahi.Uploads.StateHandoffSupervisor,
      Mahi.Uploads.ChunkUploadRegistry,
      Mahi.Uploads.ChunkUploadSupervisor
      # Start a worker by calling: Mahi.Worker.start_link(arg)
      # {Mahi.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Mahi.Supervisor)
  end

  defp topologies do
    [
      mahi: [
        strategy: Cluster.Strategy.Gossip
      ]
    ]
  end
end
