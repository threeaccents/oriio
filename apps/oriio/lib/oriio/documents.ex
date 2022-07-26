defmodule Oriio.Documents do
  @moduledoc """
  Context for dealing with documents.
  This context manages the upload, download, and transformation of documents.
  """

  alias Oriio.Uploads.ChunkUploadWorker
  alias Oriio.Uploads.ChunkUploadSupervisor
  alias Oriio.Uploads.ChunkUploadRegistry
  alias Oriio.ChunkUploadNotFound
  alias Oriio.Storages.S3FileStorage
  alias Oriio.Storages.MockFileStorage
  alias Oriio.Storages.LocalFileStorage
  alias Oriio.Storages.FileStorage
  alias Oriio.Transformations.Transformer
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
    [path_with_no_ext | _] = String.split(path, ".")

    with {:ok, document_path} <- download(path_with_no_ext) do
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

  @spec complete_chunk_upload(upload_id()) :: {:ok, url()} | {:error, term()}
  def complete_chunk_upload(upload_id) do
    pid = get_chunk_upload_pid!(upload_id)

    with {:ok, document_path} <- ChunkUploadWorker.complete_upload(pid),
         extension <- get_ext(document_path),
         {:ok, remote_document_path} <-
           upload_file_to_storage(document_path) do
      Process.exit(pid, :normal)
      {:ok, generate_url(remote_document_path, extension)}
    end
  end

  defp upload_file_to_storage(document_path) do
    {mime, mimetype} = ExMime.check_magic_bytes(document_path)

    remote_document_path = generate_remote_document_path(document_path)

    file_info = %{
      remote_document_path: remote_document_path,
      mime: Atom.to_string(mime),
      mimetype: Atom.to_string(mimetype),
      document_path: document_path
    }

    case FileStorage.upload_file(storage_engine(), file_info) do
      :ok -> {:ok, remote_document_path}
      {:error, reason} -> {:error, reason}
    end
  end

  defp storage_engine do
    storage_engine =
      Application.get_env(:oriio, :file_storage)[:storage_engine] || %S3FileStorage{}

    case storage_engine do
      "s3-compatible" ->
        %S3FileStorage{
          access_key: Application.get_env(:oriio, :file_storage)[:access_key],
          secret_key: Application.get_env(:oriio, :file_storage)[:secret_key],
          region: Application.get_env(:oriio, :file_storage)[:region],
          bucket: Application.get_env(:oriio, :file_storage)[:bucket]
        }

      "local" ->
        %LocalFileStorage{}

      "mock-engine" ->
        %MockFileStorage{}
    end
  end

  defp generate_remote_document_path(document_path) do
    file_name_with_no_ext =
      document_path
      |> String.split("/")
      |> List.last()
      |> String.split(".")
      |> List.first()

    "#{:os.system_time(:millisecond)}/#{file_name_with_no_ext}"
  end

  defp get_chunk_upload_pid!(upload_id) do
    case GenServer.whereis({:via, Horde.Registry, {ChunkUploadRegistry, upload_id}}) do
      nil ->
        raise ChunkUploadNotFound

      pid ->
        pid
    end
  end

  defp generate_url(remote_document_path, extension) do
    base_file_url() <> "/" <> remote_document_path <> "." <> extension
  end

  defp upload_id, do: UUID.generate()

  defp base_file_url, do: Application.get_env(:oriio, :base_file_url, "http://localhost:4000")

  defp get_ext(path) do
    case Path.extname(path) do
      "." <> ext -> ext
      ext -> ext
    end
  end
end
