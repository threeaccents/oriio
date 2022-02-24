defmodule Mahi.Documents do
  alias Mahi.Uploads.ChunkUploadWorker
  alias Mahi.Uploads.ChunkUploadSupervisor
  alias Mahi.Uploads.ChunkUploadRegistry
  alias Mahi.ChunkUploadNotFound
  alias Mahi.Storages.S3FileStorage
  alias Mahi.Storages.MockFileStorage
  alias Mahi.Storages.FileStorage
  alias Mahi.Mime
  alias Mahi.Transformations.Transformer

  require Logger

  @type upload_id() :: binary()
  @type file_name() :: binary()
  @type file_path() :: binary()
  @type url() :: binary()
  @type total_chunks() :: non_neg_integer()
  @type chunk_number() :: non_neg_integer()
  @type remote_file_path() :: binary()
  @type transformations() :: Transformer.transformations()

  @type transform_opts() :: [location: :remote | :local]

  @spec transform(remote_file_path() | file_path(), transformations(), transform_opts()) ::
          {:ok, file_path()} | {:error, term()}
  def transform(path, transformations, opts \\ [location: :remote])

  def transform(path, transformations, location: :remote) do
    with {:ok, file_path} <- download(path) do
      transform(file_path, transformations, location: :local)
    end
  end

  def transform(file_path, transformations, location: :local) do
    Transformer.transform_file(file_path, transformations)
  end

  @spec download(remote_file_path()) :: {:ok, file_path()} | {:error, term()}
  def download(remote_file_path) do
    FileStorage.download_file(storage_engine(), remote_file_path)
  end

  @spec upload(file_name(), file_path()) :: {:ok, url(), {:error, term()}}
  def upload(file_name, file_path) do
    file_dir = Briefly.create!(directory: true)

    upload_file_path = Path.join(file_dir, file_name)

    File.copy!(file_path, upload_file_path)

    with {:ok, remote_file_path} <- upload_file_to_storage(upload_file_path) do
      {:ok, generate_url(remote_file_path)}
    end
  end

  @spec(new_chunk_upload(file_name(), total_chunks()) :: {:ok, upload_id()}, {:error, term()})
  def new_chunk_upload(file_name, total_chunks) do
    id = upload_id()

    new_chunk_upload =
      Map.new()
      |> Map.put(:file_name, file_name)
      |> Map.put(:total_chunks, total_chunks)
      |> Map.put(:id, id)

    case ChunkUploadSupervisor.start_child({ChunkUploadWorker, new_chunk_upload}) do
      {:ok, _pid} ->
        {:ok, id}

      {:error, reason} ->
        Logger.error("failed to start ChunkUploadWorker. Reason: #{inspect(reason)}")
        {:error, :failed_to_start_chunk_upload}
    end
  end

  @spec append_chunk(upload_id(), {chunk_number(), file_path()}) :: :ok
  def append_chunk(upload_id, {chunk_number, chunk_file_path}) do
    pid = get_chunk_upload_pid!(upload_id)

    ChunkUploadWorker.append_chunk(pid, {chunk_number, chunk_file_path})
  end

  @spec complete_chunk_upload(upload_id()) :: {:ok, url()} | {:error, term()}
  def complete_chunk_upload(upload_id) do
    pid = get_chunk_upload_pid!(upload_id)

    with {:ok, file_path} <- ChunkUploadWorker.complete_upload(pid),
         {:ok, remote_file_path} <- upload_file_to_storage(file_path) do
      Process.exit(pid, :normal)
      {:ok, generate_url(remote_file_path)}
    end
  end

  defp upload_file_to_storage(file_path) do
    {mime, mimetype} = Mime.check_magic_bytes(file_path)

    remote_file_path = generate_remote_file_path(file_path, mimetype)

    file_blob = %{
      remote_location: remote_file_path,
      mime: Atom.to_string(mime),
      mimetype: Atom.to_string(mimetype),
      file_path: file_path
    }

    case FileStorage.upload_file(storage_engine(), file_blob) do
      :ok -> {:ok, remote_file_path}
      {:error, reason} -> {:error, reason}
    end
  end

  defp storage_engine do
    storage_engine =
      Application.get_env(:mahi, :file_storage)[:storage_engine] || %S3FileStorage{}

    case storage_engine do
      S3FileStorage ->
        %S3FileStorage{
          access_key: Application.get_env(:mahi, :file_storage)[:access_key],
          secret_key: Application.get_env(:mahi, :file_storage)[:secret_key],
          region: Application.get_env(:mahi, :file_storage)[:region],
          bucket: Application.get_env(:mahi, :file_storage)[:bucket]
        }

      MockFileStorage ->
        %MockFileStorage{}
    end
  end

  defp generate_remote_file_path(file_path, mimetype) do
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

  defp generate_url(remote_file_path) do
    base_file_url() <> "/" <> remote_file_path
  end

  defp upload_id, do: Ecto.UUID.generate()

  defp base_file_url, do: Application.get_env(:mahi, :base_file_url, "https://localhost:4000")
end
