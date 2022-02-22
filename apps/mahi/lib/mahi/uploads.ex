defmodule Mahi.Uploads do
  alias Mahi.Uploads.ChunkUploadServer
  alias Mahi.Uploads.ChunkUploadSupervisor
  alias Mahi.Uploads.ChunkUploadRegistry
  alias Mahi.ChunkUploadNotFound

  def new_chunk_upload(file_name, file_size, total_chunks) do
    id = upload_id()

    new_chunk_upload =
      Map.new()
      |> Map.put(:file_name, file_name)
      |> Map.put(:file_size, file_size)
      |> Map.put(:total_chunks, total_chunks)
      |> Map.put(:id, id)

    {:ok, _pid} = ChunkUploadSupervisor.start_child({ChunkUploadServer, new_chunk_upload})

    id
  end

  def append_chunk(upload_id, {chunk_number, chunk_file_path}) do
    pid = get_chunk_upload_pid!(upload_id)

    ChunkUploadServer.append_chunk(pid, {chunk_number, chunk_file_path})
  end

  def complete_chunk_upload(upload_id) do
    pid = get_chunk_upload_pid!(upload_id)

    file_path = ChunkUploadServer.complete_upload(pid)

    # get metadata
    # generate url
    # upload to storage

    file_path
  end

  def get_chunk_upload_pid!(upload_id) do
    case GenServer.whereis({:via, Horde.Registry, {ChunkUploadRegistry, upload_id}}) do
      nil ->
        raise ChunkUploadNotFound

      pid ->
        pid
    end
  end

  defp upload_id, do: for(_ <- 1..10, into: "", do: <<Enum.random('0123456789abcdef')>>)
end
