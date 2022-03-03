defmodule Oriio.SignedUploads do
  alias Plug.Crypto
  alias Ecto.UUID
  alias Oriio.Documents
  alias Oriio.Uploads.ChunkUploadWorker
  alias Oriio.Uploads.ChunkUploadRegistry
  alias Oriio.ChunkUploadNotFound

  require Logger

  @signed_upload_salt "oriio-is-awesome"

  @type upload_token() :: term()
  @type signed_upload_id() :: UUID.t()
  @type signed_upload_type() :: :regular | :chunked
  @type signed_upload_opts() :: [must_begin_expiry_time: non_neg_integer()]

  @spec new_signed_upload(signed_upload_type(), term(), term(), signed_upload_opts()) ::
          upload_token()
  def new_signed_upload(:chunked, file_name, total_chunks, opts \\ []) do
    {:ok, upload_id} = Documents.new_chunk_upload(file_name, total_chunks)

    # default to 5 minutes
    must_beging_expiry_time = Keyword.get(opts, :must_begin_expiry_time, 300)

    must_begin_by = DateTime.add(DateTime.utc_now(), must_beging_expiry_time)

    payload = %{
      upload_id: upload_id,
      must_begin_by: must_begin_by,
      upload_type: :chunked
    }

    {Crypto.sign(signed_upload_secret_key(), @signed_upload_salt, payload), upload_id}
  end

  @spec verify_token(upload_token()) :: :ok | {:error, term()}
  def verify_token(token) do
    with {:ok, payload} <- Crypto.verify(signed_upload_secret_key(), @signed_upload_salt, token) do
      can_continue_upload(payload)
    end
  end

  defp can_continue_upload(payload) do
    %{upload_id: upload_id, must_begin_by: must_begin_by} = payload

    pid = get_chunk_upload_pid!(upload_id)

    is_must_begin_by_expired? = DateTime.diff(must_begin_by, DateTime.utc_now()) <= 0

    has_upload_started? = ChunkUploadWorker.has_upload_started?(pid)

    # could figure out a clearer way to show the intent here but good for now.
    case {has_upload_started?, is_must_begin_by_expired?} do
      {true, _} -> :ok
      {false, false} -> :ok
      {false, true} -> {:error, :signed_upload_expired}
    end
  end

  defp get_chunk_upload_pid!(upload_id) do
    case GenServer.whereis({:via, Horde.Registry, {ChunkUploadRegistry, upload_id}}) do
      nil ->
        raise ChunkUploadNotFound

      pid ->
        pid
    end
  end

  defp signed_upload_secret_key, do: Application.get_env(:oriio, :signed_upload_secret_key)
end
