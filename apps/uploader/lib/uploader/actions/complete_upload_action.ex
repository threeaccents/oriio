defmodule Uploader.CompleteUploadAction do
  use Banzai

  alias Uploader.UploadWorker
  alias Uploader.Domain.MissingChunksError
  alias Uploader.Domain.Chunk

  @type t() :: %__MODULE__{}

  embedded_schema do
    field(:upload_id, :binary_id)

    embeds_one(:upload_pid, PID)
    embeds_many(:chunks, Chunk)

    field(:merged_file_path, :string)
  end

  def perform(params) do
    %__MODULE__{}
    |> new(params)
    |> step(&validate_input/1)
    |> step(&get_upload_worker_pid/1)
    |> step(&get_upload_chunks/1)
    |> step(&check_missing_chunks/1)
    |> step(&merge_chunks/1)
    # |> step(&get_file_extension/1)
    # |> step(&get_file_mime/1)
    # |> step(&generate_remote_file_path/1)
    # |> step(&generate_url/1)
    # |> step(&upload_file_to_storage/1)
    # |> step(&kill_upload_worker_process/1)
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

  defp merge_chunks(%__MODULE__{chunks: chunks} = action) do
    # the chunks are sorted by chunk number so we can just loop over them and concat them.

    file_path = Briefly.create!()

    file_streams = Enum.map(chunks, &File.stream!(&1.file_path, [], 200_000))

    file_streams
    |> Stream.concat()
    |> Stream.into(File.stream!(file_path))
    |> Stream.run()

    {:ok, %__MODULE__{action | merged_file_path: file_path}}
  end
end