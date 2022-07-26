defmodule WebApi.UploadController do
  use WebApi, :controller

  alias WebApi.UploadRequest
  alias WebApi.NewChunkUploadRequest
  alias WebApi.AppendChunkRequest
  alias WebApi.CompleteChunkUploadRequest

  plug Plug.Parsers, parsers: [{:multipart, length: 10_000_000}]

  action_fallback WebApi.FallbackController

  @type conn() :: Plug.Conn.t()

  @spec upload(conn(), map()) :: conn() | {:error, term()}
  def upload(conn, params) do
    with {:ok, %{file: file}} <- UploadRequest.from_params(params),
         {:ok, file_url} <- Uploader.upload_document(file.filename, file.path) do
      data = to_camel_case(%{data: %{url: file_url}})

      conn
      |> put_status(:created)
      |> json(data)
    end
  end

  @spec new_chunk_upload(conn(), map()) :: conn() | {:error, term()}
  def new_chunk_upload(conn, params) do
    with {:ok, %{file_name: file_name, total_chunks: total_chunks}} <-
           NewChunkUploadRequest.from_params(params),
         {:ok, upload_id} <- Uploader.new_chunk_upload(file_name, total_chunks) do
      data = to_camel_case(%{data: %{upload_id: upload_id}})

      conn
      |> put_status(:created)
      |> json(data)
    end
  end

  @spec append_chunk(conn(), map()) :: conn() | {:error, term()}
  def append_chunk(conn, params) do
    with {:ok, %{upload_id: upload_id, chunk_number: chunk_number, chunk: chunk}} <-
           AppendChunkRequest.from_params(params),
         :ok <- Uploader.append_chunk(upload_id, {chunk_number, chunk.path}) do
      data = to_camel_case(%{data: %{message: "chunk was appended"}})

      conn
      |> put_status(:ok)
      |> json(data)
    end
  end

  @spec complete_chunk_upload(conn(), map()) :: conn() | {:error, term()}
  def complete_chunk_upload(conn, params) do
    with {:ok, %{upload_id: upload_id}} <- CompleteChunkUploadRequest.from_params(params),
         {:ok, file_url} <- Uploader.complete_chunk_upload(upload_id) do
      data = to_camel_case(%{data: %{url: file_url}})

      conn
      |> put_status(:created)
      |> json(data)
    end
  end
end
