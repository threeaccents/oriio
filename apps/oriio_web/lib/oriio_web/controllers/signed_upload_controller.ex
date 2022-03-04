defmodule OriioWeb.SignedUploadController do
  use OriioWeb, :controller

  alias Oriio.SignedUploads

  action_fallback OriioWeb.FallbackController

  @type conn() :: Plug.Conn.t()

  @spec create(conn(), map()) :: conn()
  def create(conn, params) do
    validate_params = %{
      upload_type: [type: :string, required: true, default: "default"]
    }

    with {:ok, %{upload_type: upload_type}} <- Tarams.cast(params, validate_params),
         {:ok, upload_type} <- parse_upload_type(upload_type),
         {:ok, token} <- SignedUploads.new_signed_upload(upload_type) do
      conn
      |> put_status(:created)
      |> put_view(OriioWeb.AuthView)
      |> render("show.json", token: token)
    end
  end

  @spec upload(conn(), map()) :: conn()
  def upload(conn, params) do
    signed_upload_id = conn.assigns.signed_upload_id

    validate_params = %{
      file: %{
        path: [type: :string, required: true],
        filename: [type: :string, required: true]
      }
    }

    with {:ok, %{file: file}} <- Tarams.cast(params, validate_params),
         {:ok, file_url} <- SignedUploads.upload(signed_upload_id, file.filename, file.path) do
      data = to_camel_case(%{data: %{url: file_url}})

      conn
      |> put_status(:created)
      |> json(data)
    end
  end

  @spec new_chunk_upload(conn(), map()) :: conn()
  def new_chunk_upload(conn, params) do
    signed_upload_id = conn.assigns.signed_upload_id

    validate_params = %{
      file_name: [type: :string, required: true],
      total_chunks: [type: :integer, required: true]
    }

    with {:ok, %{file_name: file_name, total_chunks: total_chunks}} <-
           Tarams.cast(params, validate_params),
         {:ok, upload_id} <-
           SignedUploads.new_chunk_upload(signed_upload_id, file_name, total_chunks) do
      data = to_camel_case(%{data: %{upload_id: upload_id}})

      conn
      |> put_status(:created)
      |> json(data)
    end
  end

  @spec complete_chunk_upload(conn(), map()) :: conn()
  def complete_chunk_upload(conn, params) do
    signed_upload_id = conn.assigns.signed_upload_id

    validate_params = %{
      upload_id: [type: :string, required: true]
    }

    with {:ok, %{upload_id: upload_id}} <- Tarams.cast(params, validate_params),
         {:ok, file_url} <- SignedUploads.complete_chunk_upload(signed_upload_id, upload_id) do
      data = to_camel_case(%{data: %{url: file_url}})

      conn
      |> put_status(:created)
      |> json(data)
    end
  end

  defp parse_upload_type("chunked"), do: {:ok, :chunked}
  defp parse_upload_type("default"), do: {:ok, :default}
  defp parse_upload_type(_), do: {:error, :invalid_upload_type}
end
