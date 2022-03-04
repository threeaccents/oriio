defmodule Oriio.SignedUploads do
  alias Oriio.Uploads.SignedUploadSupervisor
  alias Oriio.Uploads.SignedUploadWorker
  alias Oriio.Uploads.SignedUploadRegistry

  alias Oriio.Documents

  alias Plug.Crypto
  alias Ecto.UUID

  require Logger

  @signed_upload_salt "oriio-is-awesome"

  @type signed_upload_token() :: term()
  @type signed_upload_id() :: UUID.t()
  @type chunk_upload_id() :: UUID.t()
  @type signed_upload_type() :: :default | :chunked
  @type signed_upload_opts() :: [must_begin_expiry_time: non_neg_integer()]
  @type file_name() :: binary()
  @type total_chunks() :: non_neg_integer()
  @type signed_upload_payload() :: map()
  @type document_path() :: binary()
  @type url() :: binary()

  @valid_upload_types ~w/default chunked/a

  @spec new_signed_upload(signed_upload_type(), signed_upload_opts()) ::
          {:ok, signed_upload_token()} | {:error, term()}
  def new_signed_upload(upload_type, opts \\ []) when upload_type in @valid_upload_types do
    signed_upload_id = signed_upload_id()

    # default to 5 minutes
    must_beging_expiry_time = Keyword.get(opts, :must_begin_expiry_time, 300)

    must_begin_by = DateTime.add(DateTime.utc_now(), must_beging_expiry_time)

    payload = %{
      id: signed_upload_id,
      must_begin_by: must_begin_by,
      upload_type: upload_type
    }

    token = Crypto.sign(signed_upload_secret_key(), @signed_upload_salt, payload)

    case SignedUploadSupervisor.start_child({SignedUploadWorker, payload}) do
      {:ok, _pid} ->
        {:ok, token}

      {:error, reason} ->
        Logger.error("failed to start SignedUploadWorker. Reason: #{inspect(reason)}")
        {:error, :failed_to_start_signed_upload}
    end
  end

  @spec new_chunk_upload(signed_upload_id(), file_name(), total_chunks()) ::
          {:ok, chunk_upload_id()} | {:error, term()}
  def new_chunk_upload(signed_upload_id, file_name, total_chunks) do
    with {:ok, chunk_upload_id} <- Documents.new_chunk_upload(file_name, total_chunks),
         pid <- get_signed_upload_pid!(signed_upload_id),
         :ok <- SignedUploadWorker.start_upload(pid) do
      {:ok, chunk_upload_id}
    end
  end

  @spec upload(signed_upload_id(), file_name(), document_path()) ::
          {:ok, url()} | {:error, term()}
  def upload(signed_upload_id, file_name, document_path) do
    case Documents.upload(file_name, document_path) do
      {:ok, url} ->
        complete_signed_upload(signed_upload_id)
        {:ok, url}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec verify_token(signed_upload_token()) :: {:ok, signed_upload_payload()} | {:error, term()}
  def verify_token(token) do
    with {:ok, payload} <- Crypto.verify(signed_upload_secret_key(), @signed_upload_salt, token),
         :ok <- can_continue_upload(payload) do
      {:ok, payload}
    end
  end

  defp can_continue_upload(%{upload_type: :chunked} = payload) do
    %{id: id, must_begin_by: must_begin_by} = payload

    pid = get_signed_upload_pid!(id)

    has_upload_started? = SignedUploadWorker.is_started?(pid)

    is_must_begin_by_expired? = DateTime.diff(must_begin_by, DateTime.utc_now()) <= 0

    # could figure out a clearer way to show the intent here but good for now.
    case {has_upload_started?, is_must_begin_by_expired?} do
      {true, _} -> :ok
      {false, false} -> :ok
      {false, true} -> {:error, :signed_upload_expired}
    end
  end

  defp can_continue_upload(payload) do
    %{id: id, must_begin_by: must_begin_by} = payload

    pid = get_signed_upload_pid!(id)

    has_upload_started? = SignedUploadWorker.is_started?(pid)

    is_must_begin_by_expired? = DateTime.diff(must_begin_by, DateTime.utc_now()) <= 0

    # could figure out a clearer way to show the intent here but good for now.
    case {has_upload_started?, is_must_begin_by_expired?} do
      {true, _} -> {:error, :signed_upload_already_in_use}
      {false, false} -> :ok
      {false, true} -> {:error, :signed_upload_expired}
    end
  end

  defp complete_signed_upload(signed_upload_id) do
    pid = get_signed_upload_pid!(signed_upload_id)

    Process.exit(pid, :normal)
  end

  defp get_signed_upload_pid!(upload_id) do
    case GenServer.whereis({:via, Horde.Registry, {SignedUploadRegistry, upload_id}}) do
      nil ->
        raise "signed upload not found"

      pid ->
        pid
    end
  end

  defp signed_upload_id, do: UUID.generate()

  defp signed_upload_secret_key, do: Application.get_env(:oriio, :signed_upload_secret_key)
end
