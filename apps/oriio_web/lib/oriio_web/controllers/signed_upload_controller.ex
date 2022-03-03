defmodule OriioWeb.SignedUploadController do
  use OriioWeb, :controller

  alias Oriio.SignedUploads

  action_fallback OriioWeb.FallbackController

  def create(conn, params) do
    validate_params = %{
      file_name: [type: :string, required: true],
      total_chunks: [type: :integer, required: true],
      upload_type: [type: :string, required: true, default: "default"]
    }

    with {:ok, %{upload_type: upload_type} = valid_params} <-
           Tarams.cast(params, validate_params),
         {:ok, upload_type} <- parse_upload_type(upload_type) do
      %{file_name: file_name, total_chunks: total_chunks} = valid_params

      token = SignedUploads.new_signed_upload(upload_type, file_name, total_chunks)

      json(conn, %{data: %{token: token}})
    end
  end

  defp parse_upload_type("chunked"), do: {:ok, :chunked}
  defp parse_upload_type("default"), do: {:ok, :default}
  defp parse_upload_type(_), do: {:error, :invalid_upload_type}
end
