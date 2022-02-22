defmodule Mahi.ChunkUploader do
  use GenServer

  alias Mahi.ChunkUploadRegistry
  alias Mahi.ChunkUploader.StateHandoff

  @type state() :: %{
          id: String.t(),
          file_name: String.t(),
          file_size: non_neg_integer(),
          total_chunks: non_neg_integer(),
          chunk_file_paths: Keyword.t(),
          received_all_chunks?: boolean()
        }

  def start_link(new_chunk_upload) do
    GenServer.start_link(__MODULE__, new_chunk_upload, name: via_tuple(new_chunk_upload.id))
  end

  def init(%{total_chunks: total_chunks} = new_chunk_upload) do
    Process.flag(:trap_exit, true)

    chunk_file_paths =
      for chunk_number <- 1..total_chunks,
          into: Keyword.new(),
          do: {int_to_atom(chunk_number), nil}

    state = Map.put(new_chunk_upload, :chunk_file_paths, chunk_file_paths)

    {:ok, state, {:continue, :load_state}}
  end

  def append_chunk(server, {chunk_number, chunk_file_path}) do
    GenServer.call(server, {:append_chunk, {chunk_number, chunk_file_path}})
  end

  def complete_upload(server) do
    GenServer.call(server, :complete_upload)
  end

  def handle_call(
        {:append_chunk, {chunk_number, chunk_file_path}},
        _from,
        %{chunk_file_paths: chunk_file_paths} = state
      ) do
    chunk_key = int_to_atom(chunk_number)

    chunk_file_paths = Keyword.put(chunk_file_paths, chunk_key, chunk_file_path)

    {:reply, :ok, %{state | chunk_file_paths: chunk_file_paths}}
  end

  def handle_call(:complete_upload, _from, state) do
    case missing_chunks(state) do
      [] ->
        # no missing chunks lets build the file
        file_path = merge_file_chunks(state)
        {:reply, file_path, state}

      missing_chunks ->
        {:reply, {:error, "missing chunks #{inspect(missing_chunks)}"}, state}
    end
  end

  def handle_continue(:load_state, %{id: id} = state) do
    new_state =
      case StateHandoff.pickup(id) do
        nil -> state
        state -> state
      end

    {:noreply, new_state}
  end

  def terminate(_reason, %{id: id} = state) do
    StateHandoff.handoff(id, state)
    # timeout to make sure the CRDT is propegated to other nodes
    :timer.sleep(1000)
  end

  defp missing_chunks(%{chunk_file_paths: chunk_file_paths}) do
    chunk_file_paths
    |> Enum.filter(fn {_key, value} -> is_nil(value) end)
    |> Keyword.keys()
    |> Enum.map(&atom_to_int/1)
  end

  defp merge_file_chunks(_state), do: ""

  defp atom_to_int(atom) do
    atom
    |> Atom.to_string()
    |> String.to_integer()
  end

  defp int_to_atom(int) do
    int
    |> Integer.to_string()
    |> String.to_atom()
  end

  defp via_tuple(name),
    do: {:via, Horde.Registry, {ChunkUploadRegistry, name}}
end
