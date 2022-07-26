# credo:disable-for-this-file
defmodule Oriio.Debug do
  @moduledoc """
  Helper module for debugging purposes
  """

  alias Uploader.{ChunkUploadRegistry, SignedUploadRegistry}
  alias Oriio.Uploads.UploadMonitorRegistry

  alias Oriio.Documents
  alias Oriio.SignedUploads

  @upload_files_path "#{__DIR__}/../../test/fixtures/uploads"

  def new_chunk_with_chunks do
    {:ok, id} = Documents.new_chunk_upload("nalu.png", 8)

    upload_chunks(id)

    id
  end

  def new_signed_upload(type) do
    {:ok, token} = SignedUploads.new_signed_upload(type)

    {:ok, payload} = SignedUploads.verify_token(token)

    {token, payload}
  end

  def upload_chunks(id) do
    document_paths =
      Path.wildcard("#{@upload_files_path}/segment**")
      |> Enum.sort()

    for {document_path, chunk_number} <- Enum.with_index(document_paths, 1) do
      Uploader.append_chunk(id, {chunk_number, document_path})
    end
  end

  def get_chunk_upload_pid(upload_id) do
    GenServer.whereis({:via, Horde.Registry, {ChunkUploadRegistry, upload_id}})
  end

  def get_signed_upload_pid(upload_id) do
    GenServer.whereis({:via, Horde.Registry, {SignedUploadRegistry, upload_id}})
  end

  def get_upload_monitor_pid do
    GenServer.whereis(
      {:via, Horde.Registry, {UploadMonitorRegistry, Oriio.Uploads.UploadMonitor}}
    )
  end
end
