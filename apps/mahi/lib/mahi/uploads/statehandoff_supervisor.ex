defmodule Oriio.Uploads.StateHandoffSupervisor do
  @moduledoc """
  Manages the supervisor lifescycle for StateHandoff.
  """

  use Supervisor

  @crdt_name Oriio.Uploads.StateHandoff.Crdt

  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    crdt_opts = [name: @crdt_name, crdt: DeltaCrdt.AWLWWMap]

    children = [
      {DeltaCrdt, crdt_opts},
      {Horde.NodeListener, Oriio.Uploads.StateHandoff},
      Oriio.Uploads.StateHandoff
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
