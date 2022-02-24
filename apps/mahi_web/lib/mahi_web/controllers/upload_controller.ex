defmodule MahiWeb.UploadController do
  use MahiWeb, :controller

  alias Mahi.Documents

  plug Plug.Parsers, parsers: [{:multipart, length: 10_000_000}]

  action_fallback MahiWeb.FallbackController

  @type conn() :: Plug.Conn.t()

  @spec upload(conn(), map()) :: conn()
  def upload(conn, params) do
    validate_params = %{
      file: %{
        path: [type: :string, required: true],
        filename: [type: :string, required: true]
      }
    }

    with {:ok, %{file: file}} <- Tarams.cast(params, validate_params),
         {:ok, file_url} <- Documents.upload(file.filename, file.path) do
      data = to_camel_case(%{data: %{url: file_url}})

      conn
      |> put_status(:created)
      |> json(data)
    end
  end

  @spec new_chunk_upload(conn(), map()) :: conn()
  def new_chunk_upload(conn, params) do
    validate_params = %{
      file_name: [type: :string, required: true],
      total_chunks: [type: :integer, required: true]
    }

    with {:ok, %{file_name: file_name, total_chunks: total_chunks}} <-
           Tarams.cast(params, validate_params),
         upload_id <- Documents.new_chunk_upload(file_name, total_chunks) do
      data = to_camel_case(%{data: %{upload_id: upload_id}})

      conn
      |> put_status(:created)
      |> json(data)
    end
  end

  @spec append_chunk(conn(), map()) :: conn()
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
         :ok <- Documents.append_chunk(upload_id, {chunk_number, chunk.path}) do
      data = to_camel_case(%{data: %{message: "chunk was appended"}})

      conn
      |> put_status(:ok)
      |> json(data)
    end
  end

  @spec complete_chunk_upload(conn(), map()) :: conn()
  def complete_chunk_upload(conn, params) do
    validate_params = %{
      upload_id: [type: :string, required: true]
    }

    with {:ok, %{upload_id: upload_id}} <- Tarams.cast(params, validate_params),
         {:ok, file_url} <- Documents.complete_chunk_upload(upload_id) do
      data = to_camel_case(%{data: %{url: file_url}})

      conn
      |> put_status(:created)
      |> json(data)
    end
  end
end
