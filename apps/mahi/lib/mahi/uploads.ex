defmodule Mahi.Uploads do
  alias Mahi.Uploads.ChunkUploadServer
  alias Mahi.Uploads.ChunkUploadSupervisor
  alias Mahi.Uploads.ChunkUploadRegistry
  alias Mahi.ChunkUploadNotFound
  alias Mahi.Storages.S3FileStorage
  alias Mahi.Storages.FileStorage
  alias Mahi.Mime

  def new_chunk_upload(file_name, total_chunks) do
    id = upload_id()

    new_chunk_upload =
      Map.new()
      |> Map.put(:file_name, file_name)
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

    with {:ok, file_path} <- ChunkUploadServer.complete_upload(pid),
         {:ok, remote_file_location} <- upload_file_to_storage(file_path) do
      Process.exit(pid, :normal)
      generate_url(remote_file_location)
    end
  end

  defp upload_file_to_storage(file_path) do
    {mime, mimetype} = Mime.check_magic_bytes(file_path)

    remote_file_location = generate_remote_file_location(file_path, mimetype)

    file_blob = %{
      remote_location: remote_file_location,
      mime: Atom.to_string(mime),
      mimetype: Atom.to_string(mimetype),
      file_path: file_path
    }

    case FileStorage.upload_file(storage_engine(), file_blob) do
      :ok -> {:ok, remote_file_location}
      {:error, reason} -> {:error, reason}
    end
  end

  defp storage_engine do
    # do a proper check later for config
    %S3FileStorage{
      access_key: Application.get_env(:mahi, :file_storage)[:access_key],
      secret_key: Application.get_env(:mahi, :file_storage)[:secret_key],
      region: Application.get_env(:mahi, :file_storage)[:region],
      bucket: Application.get_env(:mahi, :file_storage)[:bucket]
    }
  end

  defp generate_remote_file_location(file_path, mimetype) do
    file_name =
      file_path
      |> String.split("/")
      |> List.last()

    file_name = ensure_correct_extension(file_name, mimetype)

    "#{:os.system_time(:millisecond)}/#{file_name}"
  end

  defp ensure_correct_extension(file_name, mimetype) do
    file_name_with_no_ext =
      file_name
      |> String.split(".")
      |> List.first()

    # hacky but for now it works. clean up later.
    file_name_with_no_ext <> ".#{Atom.to_string(mimetype)}"
  end

  defp get_chunk_upload_pid!(upload_id) do
    case GenServer.whereis({:via, Horde.Registry, {ChunkUploadRegistry, upload_id}}) do
      nil ->
        raise ChunkUploadNotFound

      pid ->
        pid
    end
  end

  defp generate_url(remote_file_location) do
    base_file_url() <> "/" <> remote_file_location
  end

  defp upload_id, do: Ecto.UUID.generate()

  defp base_file_url, do: Application.get_env(:mahi, :base_file_url, "https://localhost:4000")
end
