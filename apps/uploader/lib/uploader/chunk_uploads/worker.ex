defmodule Uploader.UploadWorker do
  @moduledoc """
  GenServer for handling chunk uploads.
  It keeps track of all chunks uploaded and then it merges the chunks once the upload is complete.
  """

  use GenServer, restart: :transient

  alias Uploader.UploadRegistry
  alias Uploader.UploadStateHandoff, as: StateHandoff

  @type chunk() :: %{
          chunk_number: non_neg_integer(),
          chunk_file_path: String.t()
        }

  @type state() :: %{
          id: binary(),
          file_name: binary(),
          total_chunks: non_neg_integer(),
          chunks: list(chunk()),
          merged_chunks?: boolean(),
          updated_at: DateTime.t()
        }

  @type new_chunk_upload() :: %{
          upload_id: binary(),
          file_name: binary(),
          total_chunks: non_neg_integer()
        }

  @type chunk_number() :: non_neg_integer()
  @type document_path() :: binary()
  @type chunk_file_paths() :: Keyword.t()

  @spec start_link(new_chunk_upload()) :: GenServer.on_start()
  def start_link(new_chunk_upload) do
    GenServer.start_link(__MODULE__, new_chunk_upload, name: via_tuple(new_chunk_upload.upload_id))
  end

  @impl true
  def init(%{total_chunks: total_chunks} = new_chunk_upload) do
    Process.flag(:trap_exit, true)

    chunks_list =
      for chunk_number <- 1..total_chunks, do: %{chunk_number: chunk_number, chunk_file_path: nil}

    chunks = BST.new([], fn a, b -> a.chunk_number - b.chunk_number end)
    avl_chunks = AVLTree.new(fn a, b -> a.chunk_number - b.chunk_number end)

    state =
      new_chunk_upload
      |> Map.put(:chunks, chunks)
      |> Map.put(:chunks_list, chunks_list)
      |> Map.put(:chunks_map, OrderedMap.new())
      |> Map.put(:chunks_avl, avl_chunks)
      |> Map.put(:merged_chunks?, false)
      |> Map.put(:updated_at, DateTime.utc_now())

    {:ok, state, {:continue, :load_state}}
  end

  @spec fetch_chunks(pid()) :: list(chunk())
  def fetch_chunks(server) do
    GenServer.call(server, :fetch_chunk)
  end

  @spec append_chunk(pid(), chunk_number(), document_path()) :: :ok
  def append_chunk(server, chunk_number, chunk_file_path) do
    GenServer.call(server, {:append_chunk, chunk_number, chunk_file_path})
  end

  def append_chunk_avl(server, chunk_number, chunk_file_path) do
    GenServer.call(server, {:append_chunk_avl, chunk_number, chunk_file_path})
  end

  def append_chunk_map(server, chunk_number, chunk_file_path) do
    GenServer.call(server, {:append_chunk_map, chunk_number, chunk_file_path})
  end

  def append_chunk_list(server, chunk_number, chunk_file_path) do
    GenServer.call(server, {:append_chunk_list, chunk_number, chunk_file_path})
  end

  @spec complete_upload(pid()) :: {:ok, document_path()} | {:error, term()}
  def complete_upload(server) do
    GenServer.call(server, :complete_upload)
  end

  @spec updated_at(pid()) :: DateTime.t()
  def updated_at(server) do
    GenServer.call(server, :get_updated_at)
  end

  @spec has_upload_started?(pid()) :: boolean()
  def has_upload_started?(server) do
    GenServer.call(server, :has_upload_started?)
  end

  @impl GenServer
  def handle_call(
        :fetch_chunk,
        _from,
        %{chunks: chunks} = state
      ),
      do: {:reply, chunks, state}

  @impl GenServer
  def handle_call(
        {:append_chunk, chunk_number, chunk_file_path},
        _from,
        %{chunks: chunks} = state
      ) do
    # since most files passed in are temps file they get removed when the calling proccess is killed.
    # so we need to copy the file to this current process
    file_path = Briefly.create!()

    File.copy!(chunk_file_path, file_path)

    chunk = %{chunk_number: chunk_number, chunk_file_path: chunk_file_path}

    updated_chunks = BST.insert(chunks, chunk)

    {:reply, :ok, %{state | chunks: updated_chunks, updated_at: DateTime.utc_now()}}
  end

  def handle_call(
        {:append_chunk_avl, chunk_number, chunk_file_path},
        _from,
        %{chunks_avl: chunks} = state
      ) do
    # since most files passed in are temps file they get removed when the calling proccess is killed.
    # so we need to copy the file to this current process
    file_path = Briefly.create!()

    File.copy!(chunk_file_path, file_path)

    chunk = %{chunk_file_path: chunk_file_path, chunk_number: chunk_number}

    updated_chunks = AVLTree.put(chunks, chunk)

    {:reply, :ok, %{state | chunks_avl: updated_chunks, updated_at: DateTime.utc_now()}}
  end

  def handle_call(
        {:append_chunk_map, chunk_number, chunk_file_path},
        _from,
        %{chunks_map: chunks} = state
      ) do
    # since most files passed in are temps file they get removed when the calling proccess is killed.
    # so we need to copy the file to this current process
    file_path = Briefly.create!()

    File.copy!(chunk_file_path, file_path)

    updated_chunks = OrderedMap.put(chunks, chunk_number, chunk_file_path)

    {:reply, :ok, %{state | chunks_map: updated_chunks, updated_at: DateTime.utc_now()}}
  end

  def handle_call(
        {:append_chunk_list, chunk_number, chunk_file_path},
        _from,
        %{chunks_list: chunks} = state
      ) do
    # since most files passed in are temps file they get removed when the calling proccess is killed.
    # so we need to copy the file to this current process
    file_path = Briefly.create!()

    File.copy!(chunk_file_path, file_path)

    chunks_list =
      for chunk <- chunks do
        if chunk.chunk_number == chunk_number do
          Map.put(chunk, :chunk_file_path, chunk_file_path)
        else
          chunk
        end
      end

    {:reply, :ok, %{state | chunks_list: chunks_list, updated_at: DateTime.utc_now()}}
  end

  def handle_call(:complete_upload, _from, state) do
    case missing_chunks(state) do
      [] ->
        # no missing chunks lets build the file
        document_path = merge_file_chunks(state)
        {:reply, {:ok, document_path}, Map.put(state, :merged_chunks?, true)}

      missing_chunks ->
        {:reply, {:error, "missing chunks #{inspect(missing_chunks)}"}, state}
    end
  end

  def handle_call(
        :has_upload_started?,
        _from,
        %{chunk_document_paths: chunk_document_paths} = state
      ) do
    {:reply, Enum.any?(chunk_document_paths, &(elem(&1, 1) != nil)), state}
  end

  def handle_call(:get_updated_at, _from, %{updated_at: updated_at} = state),
    do: {:reply, updated_at, state}

  @impl GenServer
  def handle_continue(:load_state, %{upload_id: upload_id} = state) do
    new_state =
      case StateHandoff.pickup(upload_id) do
        nil -> state
        state -> state
      end

    {:noreply, new_state}
  end

  @impl GenServer
  def handle_info({:EXIT, _, :normal}, state) do
    {:stop, :normal, state}
  end

  def handle_info({:EXIT, _, reason}, state) do
    {:stop, reason, state}
  end

  @impl GenServer
  def terminate(:normal, _state), do: :ok

  def terminate(_reason, %{upload_id: upload_id} = state) do
    StateHandoff.handoff(upload_id, state)
    # timeout to make sure the CRDT is propegated to other nodes
    :timer.sleep(3000)
  end

  defp missing_chunks(%{chunk_document_paths: chunk_document_paths}) do
    chunk_document_paths
    |> Enum.filter(fn {_key, value} -> is_nil(value) end)
    |> Enum.map(&elem(&1, 0))
    |> Enum.map(&String.to_integer/1)
  end

  defp merge_file_chunks(%{chunk_document_paths: chunk_document_paths, file_name: file_name}) do
    file_dir = Briefly.create!(directory: true)

    merged_document_path = Path.join(file_dir, file_name)

    file_streams =
      chunk_document_paths
      |> Enum.sort(&sort_chunk_numbers/2)
      |> Enum.map(&File.stream!(elem(&1, 1), [], 200_000))

    file_streams
    |> Stream.concat()
    |> Stream.into(File.stream!(merged_document_path))
    |> Stream.run()

    merged_document_path
  end

  defp sort_chunk_numbers(a, b) do
    {aint, _} = Integer.parse(a |> elem(0))
    {bint, _} = Integer.parse(b |> elem(0))

    aint < bint
  end

  defp via_tuple(name),
    do: {:via, Horde.Registry, {UploadRegistry, name}}
end
