defmodule Uploader.ChunkUploadSupervisor do
  @moduledoc """
  Dyanamic supervisor for managing the chunk upload worker.
  It is a distributed supervisor starting up processes in any server in the cluster.
  """

  use Horde.DynamicSupervisor

  alias Horde.DynamicSupervisor, as: DistributedSupervisor

  @spec start_link(Supervisor.option()) :: Supervisor.on_start()
  def start_link(_opts) do
    DistributedSupervisor.start_link(
      __MODULE__,
      [strategy: :one_for_one, members: :auto, shutdown: 10_000],
      name: __MODULE__
    )
  end

  @impl true
  def init(init_arg) do
    [members: members()]
    |> Keyword.merge(init_arg)
    |> DistributedSupervisor.init()
  end

  @spec start_child(term()) :: Supervisor.on_start_child()
  def start_child(child_spec) do
    DistributedSupervisor.start_child(__MODULE__, child_spec)
  end

  defp members do
    Enum.map([Node.self() | Node.list()], &{__MODULE__, &1})
  end
end
