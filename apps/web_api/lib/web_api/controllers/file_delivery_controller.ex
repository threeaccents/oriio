defmodule WebApi.FileDeliveryController do
  use WebApi, :controller

  action_fallback WebApi.FallbackController

  alias Oriio.Documents
  alias WebApi.ServeFileRequest

  @type conn() :: Plug.Conn.t()

  @spec serve_file(conn(), map()) :: conn() | {:error, term()}
  def serve_file(conn, params) do
    with {:ok, valid_params} <- ServeFileRequest.from_params(params),
         {:ok, remote_document_path} <- extract_remote_document_path(valid_params),
         {:ok, transformations} <-
           extract_transformations(valid_params),
         {:ok, document_path} <- Documents.transform(remote_document_path, transformations) do
      conn
      |> put_resp_content_type(MIME.from_path(document_path))
      |> put_resp_header("cache-control", "max-age=2592000")
      |> send_file(200, document_path)
    end
  end

  @transformation_params ~w/width height crop/a

  @spec extract_transformations(map()) :: {:ok, map()}
  defp extract_transformations(params) do
    {:ok,
     params
     |> Map.take(@transformation_params)
     |> Map.put(:format, extract_format_from_file_name(params.file_name))
     |> remove_missing_transformations()}
  end

  @spec extract_format_from_file_name(String.t()) :: String.t()
  defp extract_format_from_file_name(file_name) do
    [_, ext] = String.split(file_name, ".")

    ext
  end

  @spec extract_remote_document_path(ServeFileRequest.t()) ::
          {:ok, String.t()} | {:error, :invalid_params}
  defp extract_remote_document_path(%{timestamp: ts, file_name: file_name}) do
    {:ok, DateTime.to_string(ts) <> "/" <> file_name}
  end

  @spec remove_missing_transformations(map()) :: map()
  defp remove_missing_transformations(transformations) do
    for {k, v} <- transformations, v != nil, into: %{}, do: {k, v}
  end
end
