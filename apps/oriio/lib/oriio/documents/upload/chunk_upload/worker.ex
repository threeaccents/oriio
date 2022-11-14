defmodule Oriio.Uploads.UploadWorker do
  @moduledoc """
  GenServer for handling chunk uploads.
  It keeps track of all chunks uploaded and then it merges the chunks once the upload is complete.
  """

  use GenServer, restart: :transient

  alias Oriio.Uploads.UploadRegistry
  alias Oriio.Uploads.UploadStateHandoff, as: StateHandoff

  @type state() :: %{
          id: binary(),
          file_name: binary(),
          total_chunks: non_neg_integer(),
          chunk_document_paths: Keyword.t(),
          merged_chunks?: boolean(),
          updated_at: DateTime.t()
        }

  @type new_chunk_upload() :: %{
          id: binary(),
          file_name: binary(),
          total_chunks: non_neg_integer()
        }

  @type chunk_number() :: non_neg_integer()
  @type document_path() :: binary()

  @spec start_link(new_chunk_upload()) :: GenServer.on_start()
  def start_link(new_chunk_upload) do
    GenServer.start_link(__MODULE__, new_chunk_upload, name: via_tuple(new_chunk_upload.id))
  end

  @impl true
  def init(%{total_chunks: total_chunks} = new_chunk_upload) do
    Process.flag(:trap_exit, true)

    chunk_document_paths = for chunk_number <- 1..total_chunks, do: {to_string(chunk_number), nil}

    state =
      new_chunk_upload
      |> Map.put(:chunk_document_paths, chunk_document_paths)
      |> Map.put(:merged_chunks?, false)
      |> Map.put(:updated_at, DateTime.utc_now())

    {:ok, state, {:continue, :load_state}}
  end

  @spec append_chunk(pid(), {chunk_number(), document_path()}) :: :ok
  def append_chunk(server, {chunk_number, chunk_document_path}) do
    GenServer.call(server, {:append_chunk, {chunk_number, chunk_document_path}})
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
        {:append_chunk, {chunk_number, chunk_document_path}},
        _from,
        %{chunk_document_paths: chunk_document_paths} = state
      ) do
    chunk_key = to_string(chunk_number)

    # since most files passed in are temps file they get removed when the calling proccess is killed.
    # so we need to copy the file to this current process
    document_path = Briefly.create!()

    File.copy!(chunk_document_path, document_path)

    chunk_document_paths =
      for {chunk_number, path} <- chunk_document_paths do
        if chunk_key == chunk_number do
          {chunk_key, chunk_document_path}
        else
          {chunk_number, path}
        end
      end

    {:reply, :ok,
     %{state | chunk_document_paths: chunk_document_paths, updated_at: DateTime.utc_now()}}
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
  def handle_continue(:load_state, %{id: id} = state) do
    new_state =
      case StateHandoff.pickup(id) do
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

  def terminate(_reason, %{id: id} = state) do
    StateHandoff.handoff(id, state)
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
