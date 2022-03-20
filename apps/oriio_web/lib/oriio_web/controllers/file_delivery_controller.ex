defmodule OriioWeb.FileDeliveryController do
  use OriioWeb, :controller

  action_fallback OriioWeb.FallbackController

  alias Oriio.Documents
  alias OriioWeb.ServeFileRequest

  @type conn() :: Plug.Conn.t()

  @spec serve_file(conn(), map()) :: conn()
  def serve_file(conn, params) do
    with {:ok, valid_params} <- ServeFileRequest.from_params(params),
         {:ok, remote_document_path} <- extract_remote_document_path(valid_params),
         transformations <-
           extract_transformations(valid_params),
         {:ok, document_path} <- Documents.transform(remote_document_path, transformations) do
      conn
      |> put_resp_content_type(MIME.from_path(document_path))
      |> put_resp_header("cache-control", "max-age=2592000")
      |> send_file(200, document_path)
    end
  end

  @transformation_params ~w/width height crop/a

  defp extract_transformations(params) do
    params
    |> Map.take(@transformation_params)
    |> Map.put(:format, extract_format_from_file_name(params.file_name))
    |> remove_missing_transformations()
  end

  defp extract_format_from_file_name(file_name) do
    [_, ext] = String.split(file_name, ".")

    ext
  end

  defp extract_remote_document_path(%{timestamp: ts, file_name: file_name}) do
    {:ok, ts <> "/" <> file_name}
  end

  defp extract_remote_document_path(_), do: {:error, :invalid_params}

  defp remove_missing_transformations(transformations) do
    for {k, v} <- transformations, v != nil, into: %{}, do: {k, v}
  end
end
