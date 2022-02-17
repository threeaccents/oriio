defmodule Mahi.ChunkUploader do
  use GenServer

  alias Mahi.ChunkUploadRegistry

  @type state() :: %{
          id: String.t(),
          file_name: String.t(),
          file_size: non_neg_integer(),
          total_chunks: non_neg_integer(),
          chunk_file_paths: Keyword.t()
        }

  def start_link(new_chunk_upload) do
    GenServer.start_link(__MODULE__, new_chunk_upload, name: via_tuple(new_chunk_upload.id))
  end

  def init(new_chunk_upload) do
    state = Map.put(new_chunk_upload, :chunk_file_paths, Keyword.new())
    {:ok, state}
  end

  def append_chunk(server, {chunk_number, chunk_file_path}) do
    GenServer.call(server, {:append_chunk, {chunk_number, chunk_file_path}})
  end

  def handle_call(
        {:append_chunk, {chunk_number, chunk_file_path}},
        _from,
        %{chunk_file_paths: chunk_file_paths} = state
      ) do
    chunk_key =
      chunk_number
      |> Integer.to_string()
      |> String.to_atom()

    chunk_file_paths = Keyword.put(chunk_file_paths, chunk_key, chunk_file_path)

    {:reply, :ok, %{state | chunk_file_paths: chunk_file_paths}}
  end

  defp via_tuple(name),
    do: {:via, Horde.Registry, {ChunkUploadRegistry, name}}
end
