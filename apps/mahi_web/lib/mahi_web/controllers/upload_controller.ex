defmodule MahiWeb.UploadController do
  use MahiWeb, :controller

  alias Mahi.Uploads

  plug Plug.Parsers, parsers: [{:multipart, length: 10_000_000}]

  action_fallback MahiWeb.FallbackController

  def new_chunk_upload(conn, params) do
    validate_params = %{
      file_name: [type: :string, required: true],
      total_chunks: [type: :integer, required: true]
    }

    with {:ok, valid_params} <- Tarams.cast(params, validate_params),
         upload_id <- Uploads.new_chunk_upload(valid_params.file_name, valid_params.total_chunks) do
      data = to_camel_case(%{data: %{upload_id: upload_id}})

      conn
      |> put_status(:created)
      |> json(data)
    end
  end

  def append_chunk(conn, params) do
    validate_params = %{
      chunk_number: [type: :integer, required: true],
      upload_id: [type: :string, required: true],
      chunk: %{
        path: [type: :string, required: true]
      }
    }

    with {:ok, %{upload_id: upload_id, chunk_number: chunk_number, chunk: chunk}} <-
           Tarams.cast(params, validate_params),
         :ok <- Uploads.append_chunk(upload_id, {chunk_number, chunk.path}) do
      data = to_camel_case(%{data: %{message: "chunk was appended"}})

      conn
      |> put_status(:ok)
      |> json(data)
    end
  end
end