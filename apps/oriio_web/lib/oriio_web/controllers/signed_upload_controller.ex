defmodule OriioWeb.SignedUploadController do
  use OriioWeb, :controller

  alias Oriio.SignedUploads

  action_fallback OriioWeb.FallbackController

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

  defp parse_upload_type("chunked"), do: {:ok, :chunked}
  defp parse_upload_type("default"), do: {:ok, :default}
  defp parse_upload_type(_), do: {:error, :invalid_upload_type}
end
