defmodule Mahi.Uploads.StateHandoffSupervisor do
  @moduledoc """
  Manages the supervisor lifescycle for StateHandoff.
  """

  use Supervisor

  @crdt_name Mahi.Uploads.StateHandoff.Crdt

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    crdt_opts = [name: @crdt_name, crdt: DeltaCrdt.AWLWWMap]

    children = [
      {DeltaCrdt, crdt_opts},
      {Horde.NodeListener, Mahi.Uploads.StateHandoff},
      Mahi.Uploads.StateHandoff
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
