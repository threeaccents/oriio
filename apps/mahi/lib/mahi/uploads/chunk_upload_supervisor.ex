defmodule Mahi.Uploads.ChunkUploadSupervisor do
  @moduledoc """
  Dyanamic supervisor for managing the chunk upload worker.
  It is a distributed supervisor starting up processes in any server in the cluster.
  """

  use Horde.DynamicSupervisor

  def start_link(_opts) do
    Horde.DynamicSupervisor.start_link(
      __MODULE__,
      [strategy: :one_for_one, members: :auto, shutdown: 10_000],
      name: __MODULE__
    )
  end

  def init(init_arg) do
    [members: members()]
    |> Keyword.merge(init_arg)
    |> Horde.DynamicSupervisor.init()
  end

  def start_child(child_spec) do
    Horde.DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  defp members() do
    Enum.map([Node.self() | Node.list()], &{__MODULE__, &1})
  end
end
