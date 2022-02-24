defmodule Mahi.Uploads.StateHandoff do
  @moduledoc """
  Handles state handoff between processes. It uses DeltaCRDT to manage the distributed state syncronization.
  """

  use GenServer

  alias Horde.NodeListener
  alias Mahi.Uploads.ChunkUploadWorker

  @type opts() :: Keyword.t()
  @type upload_id() :: binary()

  @type state() :: %{
          members: MapSet.t()
        }

  @type upload_state() :: ChunkUploadWorker.state()

  @crdt Mahi.Uploads.StateHandoff.Crdt

  @spec start_link(opts()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    members = NodeListener.make_members(__MODULE__)

    state =
      opts
      |> Enum.into(%{})
      |> Map.put(:members, members)

    {:ok, state}
  end

  @spec handoff(upload_id(), upload_state()) :: DeltaCrdt.t()
  def handoff(upload_id, state) do
    DeltaCrdt.put(@crdt, upload_id, state)
  end

  @spec pickup(upload_id()) :: upload_state() | nil
  def pickup(upload_id) do
    case DeltaCrdt.get(@crdt, upload_id) do
      nil ->
        nil

      upload_state ->
        DeltaCrdt.delete(@crdt, upload_id)
        upload_state
    end
  end

  @impl true
  def handle_call({:set_members, members}, _from, state) do
    neighbors =
      members
      |> Stream.filter(fn member -> member != {__MODULE__, Node.self()} end)
      |> Enum.map(fn {_, node} -> {@crdt, node} end)

    DeltaCrdt.set_neighbours(@crdt, neighbors)

    {:reply, :ok, %{state | members: members}}
  end

  @impl true
  def handle_call(:members, _from, %{members: members} = state) do
    {:reply, members, state}
  end
end
