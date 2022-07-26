defmodule WebApi.SignedUploadController do
  use WebApi, :controller

  alias Oriio.SignedUploads
  alias WebApi.UploadRequest
  alias WebApi.CompleteChunkUploadRequest
  alias WebApi.NewChunkUploadRequest
  alias WebApi.CreateSignedUploadRequest

  action_fallback WebApi.FallbackController

  @type conn() :: Plug.Conn.t()

  @spec create(conn(), map()) :: conn() | {:error, term()}
  def create(conn, params) do
    with {:ok, %{upload_type: upload_type}} <- CreateSignedUploadRequest.from_params(params),
         {:ok, token} <- SignedUploads.new_signed_upload(upload_type) do
      conn
      |> put_status(:created)
      |> put_view(WebApi.AuthView)
      |> render("show.json", token: token)
    end
  end

  @spec upload(conn(), map()) :: conn() | {:error, term()}
  def upload(conn, params) do
    signed_upload_id = conn.assigns.signed_upload_id

    with {:ok, %{file: file}} <- UploadRequest.from_params(params),
         {:ok, file_url} <- SignedUploads.upload(signed_upload_id, file.filename, file.path) do
      data = to_camel_case(%{data: %{url: file_url}})

      conn
      |> put_status(:created)
      |> json(data)
    end
  end

  @spec new_chunk_upload(conn(), map()) :: conn() | {:error, term()}
  def new_chunk_upload(conn, params) do
    signed_upload_id = conn.assigns.signed_upload_id

    with {:ok, %{file_name: file_name, total_chunks: total_chunks}} <-
           NewChunkUploadRequest.from_params(params),
         {:ok, upload_id} <-
           SignedUploads.new_chunk_upload(signed_upload_id, file_name, total_chunks) do
      data = to_camel_case(%{data: %{upload_id: upload_id}})

      conn
      |> put_status(:created)
      |> json(data)
    end
  end

  @spec complete_chunk_upload(conn(), map()) :: conn() | {:error, term()}
  def complete_chunk_upload(conn, params) do
    signed_upload_id = conn.assigns.signed_upload_id

    with {:ok, %{upload_id: upload_id}} <- CompleteChunkUploadRequest.from_params(params),
         {:ok, file_url} <- SignedUploads.complete_chunk_upload(signed_upload_id, upload_id) do
      data = to_camel_case(%{data: %{url: file_url}})

      conn
      |> put_status(:created)
      |> json(data)
    end
  end
end
