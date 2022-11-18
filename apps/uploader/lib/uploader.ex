defmodule Uploader do
  @moduledoc """
  Documentation for `Uploader`.
  """

  alias Oriio.Storages.S3FileStorage
  alias Oriio.Storages.MockFileStorage
  alias Oriio.Storages.LocalFileStorage
  alias Oriio.Storages.FileStorage
  alias Uploader.UploadWorker
  alias Uploader.UploadRegistry
  alias Uploader.UploadNotFound
  alias Ecto.UUID
  alias Uploader.CreateNewUploadAction
  alias Uploader.CompleteUploadAction

  require Logger

  @type upload_id() :: binary()
  @type file_name() :: binary()
  @type document_path() :: binary()
  @type url() :: binary()
  @type total_chunks() :: non_neg_integer()
  @type chunk_number() :: non_neg_integer()
  @type remote_document_path() :: binary()

  @spec new_upload(file_name(), total_chunks()) :: {:ok, upload_id()} | {:error, term()}
  def new_upload(file_name, total_chunks) do
    params = %{file_name: file_name, total_chunks: total_chunks}

    case CreateNewUploadAction.perform(params) do
      {:ok, %{upload_id: upload_id}} -> {:ok, upload_id}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec append_chunk(upload_id(), {chunk_number(), document_path()}) :: :ok
  def append_chunk(upload_id, {chunk_number, chunk_file_path}) do
    pid = get_upload_pid!(upload_id)

    UploadWorker.append_chunk(pid, chunk_number, chunk_file_path)
  end

  @spec complete_upload(upload_id()) :: {:ok, url()} | {:error, term()}
  def complete_upload(upload_id) do
    params = %{upload_id: upload_id}

    case CompleteUploadAction.perform(params) do
      {:ok, %{file_path: file_path}} -> {:ok, file_path}
      {:error, reason} -> {:error, reason}
    end
  end

  def get_upload_pid!(upload_id) do
    case GenServer.whereis({:via, Horde.Registry, {UploadRegistry, upload_id}}) do
      nil ->
        raise UploadNotFound

      pid ->
        pid
    end
  end
end
