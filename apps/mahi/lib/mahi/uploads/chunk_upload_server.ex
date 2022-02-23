defmodule Mahi.Uploads.ChunkUploadServer do
  use GenServer, restart: :transient

  alias Mahi.Uploads.ChunkUploadRegistry
  alias Mahi.Uploads.StateHandoff

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
        {:reply, {:ok, file_path}, state}

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

  def handle_info({:EXIT, _, :normal}, state) do
    {:stop, :normal, state}
  end

  def terminate(:normal, _state), do: :ok

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

  defp merge_file_chunks(%{chunk_file_paths: chunk_file_paths, file_name: file_name}) do
    file_dir = Briefly.create!(directory: true)

    merged_file_path = Path.join(file_dir, file_name)

    file_streams =
      chunk_file_paths
      |> Enum.sort(&sort_chunk_numbers/2)
      |> Enum.map(&File.stream!(elem(&1, 1), [], 200_000))

    Stream.concat(file_streams)
    |> Stream.into(File.stream!(merged_file_path))
    |> Stream.run()

    merged_file_path
  end

  defp sort_chunk_numbers(a, b) do
    {aint, _} = Integer.parse(Atom.to_string(a |> elem(0)))
    {bint, _} = Integer.parse(Atom.to_string(b |> elem(0)))

    aint < bint
  end

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
