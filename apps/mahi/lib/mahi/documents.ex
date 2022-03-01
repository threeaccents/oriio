defmodule Mahi.Documents do
  @moduledoc """
  Context for dealing with documents.
  This context manages the upload, download, and transformation of documents.
  """

  alias Mahi.Uploads.ChunkUploadWorker
  alias Mahi.Uploads.ChunkUploadSupervisor
  alias Mahi.Uploads.ChunkUploadRegistry
  alias Mahi.ChunkUploadNotFound
  alias Mahi.Storages.S3FileStorage
  alias Mahi.Storages.MockFileStorage
  alias Mahi.Storages.FileStorage
  alias Mahi.Mime
  alias Mahi.Transformations.Transformer
  alias Ecto.UUID

  require Logger

  @type upload_id() :: binary()
  @type file_name() :: binary()
  @type document_path() :: binary()
  @type url() :: binary()
  @type total_chunks() :: non_neg_integer()
  @type chunk_number() :: non_neg_integer()
  @type remote_document_path() :: binary()
  @type transformations() :: Transformer.transformations()

  @type transform_opts() :: [location: :remote | :local]

  @spec transform(remote_document_path() | document_path(), transformations(), transform_opts()) ::
          {:ok, document_path()} | {:error, term()}
  def transform(path, transformations, opts \\ [location: :remote])

  def transform(path, transformations, location: :remote) do
    with {:ok, document_path} <- download(path) do
      transform(document_path, transformations, location: :local)
    end
  end

  def transform(document_path, transformations, location: :local) do
    Transformer.transform_file(document_path, transformations)
  end

  @spec download(remote_document_path()) :: {:ok, document_path()} | {:error, term()}
  def download(remote_document_path) do
    FileStorage.download_file(storage_engine(), remote_document_path)
  end

  @spec upload(file_name(), document_path()) :: {:ok, url()} | {:error, term()}
  def upload(file_name, document_path) do
    file_dir = Briefly.create!(directory: true)

    upload_document_path = Path.join(file_dir, file_name)

    File.copy!(document_path, upload_document_path)

    with {:ok, remote_document_path} <- upload_file_to_storage(upload_document_path) do
      {:ok, generate_url(remote_document_path)}
    end
  end

  @spec new_chunk_upload(file_name(), total_chunks()) :: {:ok, upload_id()} | {:error, term()}
  def new_chunk_upload(file_name, total_chunks) do
    id = upload_id()

    new_chunk_upload =
      Map.new()
      |> Map.put(:file_name, file_name)
      |> Map.put(:total_chunks, total_chunks)
      |> Map.put(:id, id)
      |> Map.put(:updated_at, DateTime.utc_now())

    case ChunkUploadSupervisor.start_child({ChunkUploadWorker, new_chunk_upload}) do
      {:ok, _pid} ->
        {:ok, id}

      {:error, reason} ->
        Logger.error("failed to start ChunkUploadWorker. Reason: #{inspect(reason)}")
        {:error, :failed_to_start_chunk_upload}
    end
  end

  @spec append_chunk(upload_id(), {chunk_number(), document_path()}) :: :ok
  def append_chunk(upload_id, {chunk_number, chunk_document_path}) do
    document_path = Briefly.create!()

    File.copy!(chunk_document_path, document_path)

    pid = get_chunk_upload_pid!(upload_id)

    ChunkUploadWorker.append_chunk(pid, {chunk_number, document_path})
  end

  @spec complete_chunk_upload(upload_id()) :: {:ok, url()} | {:error, term()}
  def complete_chunk_upload(upload_id) do
    pid = get_chunk_upload_pid!(upload_id)

    with {:ok, document_path} <- ChunkUploadWorker.complete_upload(pid),
         {:ok, remote_document_path} <- upload_file_to_storage(document_path) do
      Process.exit(pid, :normal)
      {:ok, generate_url(remote_document_path)}
    end
  end

  defp upload_file_to_storage(document_path) do
    {mime, mimetype} = Mime.check_magic_bytes(document_path)

    remote_document_path = generate_remote_document_path(document_path, mimetype)

    file_blob = %{
      remote_document_path: remote_document_path,
      mime: Atom.to_string(mime),
      mimetype: Atom.to_string(mimetype),
      document_path: document_path
    }

    case FileStorage.upload_file(storage_engine(), file_blob) do
      :ok -> {:ok, remote_document_path}
      {:error, reason} -> {:error, reason}
    end
  end

  defp storage_engine do
    storage_engine =
      Application.get_env(:mahi, :file_storage)[:storage_engine] || %S3FileStorage{}

    case storage_engine do
      "s3-compatible" ->
        %S3FileStorage{
          access_key: Application.get_env(:mahi, :file_storage)[:access_key],
          secret_key: Application.get_env(:mahi, :file_storage)[:secret_key],
          region: Application.get_env(:mahi, :file_storage)[:region],
          bucket: Application.get_env(:mahi, :file_storage)[:bucket]
        }

      "mock-engine" ->
        %MockFileStorage{}
    end
  end

  defp generate_remote_document_path(document_path, mimetype) do
    file_name =
      document_path
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

  defp generate_url(remote_document_path) do
    base_file_url() <> "/" <> remote_document_path
  end

  defp upload_id, do: UUID.generate()

  defp base_file_url, do: Application.get_env(:mahi, :base_file_url, "https://localhost:4000")
end
