defmodule Oriio.Documents do
  @moduledoc """
  Context for dealing with documents.
  This context manages the upload, download, and transformation of documents.
  """

  alias Oriio.Uploads.UploadWorker
  alias Oriio.Uploads.UploadSupervisor
  alias Oriio.Uploads.UploadRegistry
  alias Oriio.UploadNotFound
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
end
