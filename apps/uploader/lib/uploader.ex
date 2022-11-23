defmodule Uploader do
  @moduledoc """
  Documentation for `Uploader`.
  """

  alias Uploader.UploadWorker
  alias Uploader.UploadRegistry
  alias Uploader.UploadNotFound
  alias Uploader.CreateNewUploadAction
  alias Uploader.CompleteUploadAction
  alias Uploader.Domain.Types

  require Logger

  @spec new_upload(Types.file_name(), Types.total_chunks()) ::
          {:ok, Types.upload_id()} | {:error, term()}
  def new_upload(file_name, total_chunks) do
    params = %{file_name: file_name, total_chunks: total_chunks}

    case CreateNewUploadAction.perform(params) do
      {:ok, %{upload_id: upload_id}} -> {:ok, upload_id}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec append_chunk(Types.upload_id(), Types.chunk_number(), Types.document_path()) :: :ok
  def append_chunk(upload_id, chunk_number, chunk_file_path) do
    pid = get_upload_pid!(upload_id)

    UploadWorker.append_chunk(pid, chunk_number, chunk_file_path)
  end

  @spec complete_upload(Types.upload_id()) :: {:ok, Types.url()} | {:error, term()}
  def complete_upload(upload_id) do
    params = %{upload_id: upload_id}

    case CompleteUploadAction.perform(params) do
      {:ok, %{file_path: file_path}} -> {:ok, file_path}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec get_upload_pid!(Types.upload_id()) :: pid()
  def(get_upload_pid!(upload_id)) do
    case GenServer.whereis({:via, Horde.Registry, {UploadRegistry, upload_id}}) do
      nil ->
        raise UploadNotFound

      pid ->
        pid
    end
  end
end
