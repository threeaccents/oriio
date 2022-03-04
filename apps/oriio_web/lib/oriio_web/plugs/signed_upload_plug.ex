defmodule OriioWeb.SignedUploadPlug do
  import Plug.Conn

  import Phoenix.Controller, only: [put_view: 2, render: 3]

  alias Oriio.SignedUploads

  require Logger

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, payload} <- SignedUploads.verify_token(token) do
      assign(conn, :signed_upload_id, payload.id)
    else
      [] ->
        send_bad_request_resp(conn, "bearer token missing")

      {:error, :signed_upload_expired} ->
        send_bad_request_resp(conn, "signed upload expired")

      {:error, reason} ->
        Logger.warn("failed to verify token: #{inspect(reason)}")
        send_unauthorized_resp(conn)
    end
  end

  defp send_unauthorized_resp(conn) do
    conn
    |> put_status(:unauthorized)
    |> put_view(OriioWeb.ErrorView)
    |> render("error.json", %{error: {:error, :unauthorized}})
    |> halt()
  end

  defp send_bad_request_resp(conn, error) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(OriioWeb.ErrorView)
    |> render("error.json", %{message: error})
    |> halt()
  end
end
