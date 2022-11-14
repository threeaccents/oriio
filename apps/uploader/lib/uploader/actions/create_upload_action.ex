defmodule Uploader.CreateNewUploadAction do
  use Banzai

  alias Ecto.UUID
  alias Uploader.UploadSupervisor
  alias Uploader.UploadWorker

  require Logger

  @type t() :: %__MODULE__{}

  @type params() :: %{
          file_name: String.t(),
          total_chunks: non_neg_integer()
        }

  embedded_schema do
    # inputs
    field(:file_name, :string)
    field(:total_chunks, :integer)

    # internal token fields
    field(:upload_id, :binary_id)
    field(:worker_started?, :boolean)
  end

  @spec perform(params()) :: t()
  def perform(params) do
    %__MODULE__{}
    |> new(params)
    |> step(&validate_input/1)
    |> step(&generate_upload_id/1)
    |> step(&initialize_upload_worker/1)
    |> run()
  end

  defp validate_input(action = %__MODULE__{file_name: file_name, total_chunks: total_chunks})
       when is_binary(file_name) and is_integer(total_chunks),
       do: {:ok, action}

  defp validate_input(_), do: {:error, :invalid_input}

  defp generate_upload_id(action = %__MODULE__{}) do
    upload_id = UUID.generate()

    {:ok, %__MODULE__{action | upload_id: upload_id}}
  end

  defp initialize_upload_worker(action = %__MODULE__{}) do
    initial_upload_state = Map.take(action, ~w(file_name total_chunks upload_id)a)

    case UploadSupervisor.start_child({UploadWorker, initial_upload_state}) do
      {:ok, _pid} ->
        {:ok, action}

      {:error, reason} ->
        Logger.error("failed to start UploadWorker. Reason: #{inspect(reason)}")
        {:error, :failed_to_start_upload}
    end
  end
end
