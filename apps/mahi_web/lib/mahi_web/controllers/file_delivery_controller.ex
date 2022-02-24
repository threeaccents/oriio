defmodule MahiWeb.FileDeliveryController do
  use MahiWeb, :controller

  action_fallback MahiWeb.FallbackController

  alias Mahi.Downloads

  def serve_file(conn, params) do
    validate_params = %{
      timestamp: [type: :string, required: true],
      file_name: [type: :string, required: true]
    }

    with {:ok, valid_params} <- Tarams.cast(params, validate_params),
         {:ok, remote_file_location} <- extract_remote_file_location(valid_params),
         {:ok, file_path} <- Downloads.download(remote_file_location) do
      send_file(conn, 200, file_path)
    end
  end

  defp extract_remote_file_location(%{timestamp: ts, file_name: file_name}) do
    {:ok, ts <> "/" <> file_name}
  end

  defp extract_remote_file_location(_), do: {:error, :invalid_params}
end
