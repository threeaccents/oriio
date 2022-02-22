defmodule Mahi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Cluster.Supervisor, [topologies(), [name: Mahi.ClusterSupervisor]]},
      Mahi.ChunkUploader.StateHandoff,
      Mahi.ChunkUploadRegistry,
      Mahi.ChunkUploadSupervisor

      # Starts a worker by calling: Mahi.Worker.start_link(arg)
      # {Mahi.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mahi.Supervisor, shutdown: 10_000]
    Supervisor.start_link(children, opts)
  end

  defp topologies do
    [
      mahi: [
        strategy: Cluster.Strategy.Gossip
      ]
    ]
  end
end
