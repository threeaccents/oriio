defmodule Uploader.CompleteUploadAction do
  @moduledoc """
  CompleteUploadAction validates that all chunks have been uploaded.
  It then concatenates all the chunks into 1 file and uploads that file to storage.
  Once storage upload is complete the UploadWorker for this upload is cleaned up.
  """
  use Banzai

  alias Uploader.UploadWorker
  alias Uploader.Domain.MissingChunksError
  alias Uploader.Domain.Chunk

  @type t() :: %__MODULE__{}

  embedded_schema do
    field(:upload_id, :binary_id)

    embeds_one(:upload_pid, PID)
    embeds_many(:chunks, Chunk)

    field(:concatenated_file_path, :string)
    field(:file_key, :string)
  end

  def perform(params) do
    %__MODULE__{}
    |> new(params)
    |> step(&validate_input/1)
    |> step(&get_upload_worker_pid/1)
    |> step(&get_upload_chunks/1)
    |> step(&check_missing_chunks/1)
    |> step(&concatenate_chunks/1)
    |> step(&upload_file_to_storage/1)
    |> step(&kill_upload_worker_process/1)
    |> run()
  end

  defp validate_input(action), do: {:ok, action}

  defp get_upload_worker_pid(action = %__MODULE__{upload_id: upload_id}) do
    {:ok, %__MODULE__{action | upload_pid: Uploader.get_upload_pid!(upload_id)}}
  end

  defp get_upload_chunks(action = %__MODULE__{upload_pid: upload_pid}) do
    chunks = UploadWorker.fetch_chunks(upload_pid)

    {:ok, %__MODULE__{action | chunks: chunks}}
  end

  defp check_missing_chunks(%__MODULE__{chunks: chunks, upload_id: upload_id} = action) do
    case get_missing_chunks(chunks) do
      [] ->
        {:ok, action}

      missing_chunks ->
        {:error, %MissingChunksError{chunks: missing_chunks, upload_id: upload_id}}
    end
  end

  defp get_missing_chunks(chunks) do
    chunks
    |> Enum.filter(fn %Chunk{file_path: file_path} -> is_nil(file_path) end)
    |> Enum.map(& &1.chunk_number)
  end

  defp concatenate_chunks(%__MODULE__{chunks: chunks, upload_pid: upload_pid} = action) do
    file_name = UploadWorker.get_file_name(upload_pid)

    file_path = Briefly.create!()

    # the chunks are sorted by chunk number so we can just loop over them and concat them.
    file_streams = Enum.map(chunks, &File.stream!(&1.file_path, [], 200_000))

    first_chunk = List.first(chunks)

    # we only need the first 216 bytes to determine the file mime.
    # so we can just pass in the first chunk of the file
    {mime, mimetype} =
      first_chunk.file_path
      |> File.open!()
      |> ExMime.check_magic_bytes()

    metadata =
      %{mime: mime, mimetype: mimetype, original_filename: file_name}
      |> :erlang.term_to_binary()
      |> :erlang.binary_to_list()

    stream = File.stream!(file_path)

    Stream.into(metadata, file_path)

    file_streams
    |> Stream.concat()
    |> Stream.into(stream)
    |> Stream.run()

    {:ok, %__MODULE__{action | concatenated_file_path: file_path}}
  end

  defp upload_file_to_storage(
         %__MODULE__{file_key: file_key, concatenated_file_path: file_path} = action
       ) do
    # case Storage.save(file_key, file_path) do
    #   :ok ->
    #     action
    #
    #   {:error, reason} ->
    #     {:error, reason}
    # end
    {:ok, action}
  end

  defp kill_upload_worker_process(%__MODULE__{upload_pid: upload_pid} = action) do
    Process.exit(upload_pid, :normal)

    {:ok, action}
  end
end
