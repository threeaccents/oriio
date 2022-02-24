defmodule MahiWeb.FileDeliveryController do
  use MahiWeb, :controller

  action_fallback MahiWeb.FallbackController

  alias Mahi.Documents

  def serve_file(conn, params) do
    validate_params = %{
      timestamp: [type: :string, required: true],
      file_name: [type: :string, required: true],
      width: :integer,
      height: :integer,
      crop: :boolean
    }

    with {:ok, valid_params} <- Tarams.cast(params, validate_params),
         {:ok, remote_file_path} <- extract_remote_file_path(valid_params),
         transformations <-
           extract_transformations(valid_params),
         {:ok, file_path} <- Documents.transform(remote_file_path, transformations) do
      send_file(conn, 200, file_path)
    else
      error ->
        IO.inspect(error)
        error
    end
  end

  @transformation_params ~w/width height crop/a

  defp extract_transformations(params) do
    params
    |> Map.take(@transformation_params)
    |> remove_missing_transformations()
  end

  defp extract_remote_file_path(%{timestamp: ts, file_name: file_name}) do
    {:ok, ts <> "/" <> file_name}
  end

  defp extract_remote_file_path(_), do: {:error, :invalid_params}

  defp remove_missing_transformations(transformations) do
    for {k, v} <- transformations, v != nil, into: %{}, do: {k, v}
  end
end