defmodule Mahi.ChunkUpload.StateHandoff do
  use GenServer

  @crdt Mahi.ChunkUpload.StateHandoff.Crdt

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  @impl true
  def init(opts) do
    members = Horde.NodeListener.make_members(opts[:name])

    state =
      opts
      |> Enum.into(%{})
      |> Map.put(:members, members)

    {:ok, state}
  end

  def handoff(upload_id, state) do
    DeltaCrdt.put(@crdt, upload_id, state)
  end

  def pickup(upload_id) do
    case DeltaCrdt.get(@crdt, upload_id) do
      nil ->
        nil

      state ->
        DeltaCrdt.delete(@crdt, upload_id)
        state
    end
  end

  @impl true
  def handle_call({:set_members, members}, _from, state = %{crdt: crdt, name: name}) do
    neighbors =
      members
      |> Stream.filter(fn member -> member != {name, Node.self()} end)
      |> Enum.map(fn {_, node} -> {crdt, node} end)

    DeltaCrdt.set_neighbours(crdt, neighbors)

    {:reply, :ok, %{state | members: members}}
  end

  @impl true
  def handle_call(:members, _from, state = %{members: members}) do
    {:reply, members, state}
  end
end
