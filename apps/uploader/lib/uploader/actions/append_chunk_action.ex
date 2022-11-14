defmodule Uploader.CompleteUploadAction do
  use Banzai

  alias Uploader.UploadRegistry
  alias Uploader.UploadNotFound
  alias Uploader.UploadWorker

  @type t() :: %__MODULE__{}

  embedded_schema do
    field(:upload_id, :binary_id)

    embeds_one(:upload_pid, PID)
    field(:chunk_file_paths, {:array, :map})
  end

  def perform(params) do
    %__MODULE__{}
    |> new(params)
    |> step(&validate_input/1)
    |> step(&get_upload_worker_pid/1)
    |> step(&get_upload_chunks/1)
    # |> step(&merge_chunks/1)
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
    case GenServer.whereis({:via, Horde.Registry, {UploadRegistry, upload_id}}) do
      nil ->
        {:error, :upload_not_found}

      pid ->
        {:ok, %__MODULE__{action | upload_pid: pid}}
    end
  end

  defp get_upload_chunks(action = %__MODULE__{upload_pid: upload_pid}) do
    chunk_file_paths = UploadWorker.fetch_chunks(upload_pid)

    {:ok, %__MODULE__{action | chunk_file_paths: chunk_file_paths}}
  end
end
