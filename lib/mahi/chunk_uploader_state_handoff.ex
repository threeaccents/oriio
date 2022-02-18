defmodule Mahi.ChunkUploader.StateHandoff do
  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    {:ok, crdt_pid} = DeltaCrdt.start_link(DeltaCrdt.AWLWWMap, sync_interval: 100)

    {:ok, crdt_pid}
  end

  def join(other_node) do
    Logger.warn("Joining StateHandoff at #{inspect(other_node)}")

    GenServer.call(__MODULE__, {:add_neighbours, {__MODULE__, other_node}})
  end

  def handoff(upload_id, state) do
    GenServer.call(__MODULE__, {:handoff, upload_id, state})
  end

  def pickup(upload_id) do
    GenServer.call(__MODULE__, {:pickup, upload_id})
  end

  def handle_call({:add_neighbours, other_node}, _from, this_crdt_pid) do
    Logger.warn(
      "Sending :add_neighbours to #{inspect(other_node)} with #{inspect(this_crdt_pid)}"
    )

    # pass our crdt pid in a message so that the crdt on other_node can add it as a neighbour
    # expect other_node to send back it's crdt_pid in response
    other_crdt_pid = GenServer.call(other_node, {:fulfill_add_neighbours, this_crdt_pid})
    # add other_node's crdt_pid as a neighbour, we need to add both ways so changes in either
    # are reflected across, otherwise it would be one way only
    DeltaCrdt.set_neighbours(this_crdt_pid, [other_crdt_pid])

    {:reply, :ok, this_crdt_pid}
  end

  def handle_call({:fulfill_add_neighbours, other_crdt_pid}, _from, this_crdt_pid) do
    Logger.warn("Adding neighbour #{inspect(other_crdt_pid)} to this #{inspect(this_crdt_pid)}")
    # add the crdt's as a neighbour, pass back our crdt to the original adding node via a reply
    DeltaCrdt.set_neighbours(this_crdt_pid, [other_crdt_pid])
    {:reply, this_crdt_pid, this_crdt_pid}
  end

  def handle_call({:handoff, upload_id, state}, _from, crdt_pid) do
    DeltaCrdt.put(crdt_pid, :add, [upload_id, state])
    Logger.warn("Added #{upload_id}'s order '#{inspect(state)} to crdt")
    Logger.warn("CRDT: #{inspect(DeltaCrdt.get(crdt_pid, upload_id))}")
    {:reply, :ok, crdt_pid}
  end

  def handle_call({:pickup, upload_id}, _from, crdt_pid) do
    state = DeltaCrdt.get(crdt_pid, upload_id)

    Logger.warn("CRDT: #{inspect(DeltaCrdt.get(crdt_pid, upload_id))}")
    Logger.warn("Picked up #{inspect(state, charlists: :as_lists)} for #{upload_id}")
    # remove when picked up, this is a temporary storage and not meant to be used
    #  in any implementation beyond restarting of cross Pod processes
    DeltaCrdt.delete(crdt_pid, upload_id)

    {:reply, state, crdt_pid}
  end
end
