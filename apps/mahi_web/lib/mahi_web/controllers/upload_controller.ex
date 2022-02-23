defmodule MahiWeb.UploadController do
  use MahiWeb, :controller

  alias Mahi.Uploads

  plug Plug.Parsers, parsers: [{:multipart, length: 10_000_000}]

  action_fallback MahiWeb.FallbackController

  def upload(conn, params) do
    IO.inspect(params)
    validate_params = %{
      file: %{
        path: [type: :string, required: true],
        filename: [type: :string, required: true]
      }
    }

    with {:ok, %{file: file}} <- Tarams.cast(params, validate_params),
         {:ok, file_url} <- Uploads.upload(file.filename, file.path) do
          data = to_camel_case(%{data: %{url: file_url}})

          conn
          |> put_status(:created)
          |> json(data)
    end
  end

  def new_chunk_upload(conn, params) do
    validate_params = %{
      file_name: [type: :string, required: true],
      total_chunks: [type: :integer, required: true]
    }

    with {:ok, %{file_name: file_name, total_chunks: total_chunks}} <-
           Tarams.cast(params, validate_params),
         upload_id <- Uploads.new_chunk_upload(file_name, total_chunks) do
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

  def complete_chunk_upload(conn, params) do
    validate_params = %{
      upload_id: [type: :string, required: true]
    }

    with {:ok, %{upload_id: upload_id}} <- Tarams.cast(params, validate_params),
         {:ok, file_url} <- Uploads.complete_chunk_upload(upload_id) do
      data = to_camel_case(%{data: %{url: file_url}})

      conn
      |> put_status(:created)
      |> json(data)
    end
  end

end
