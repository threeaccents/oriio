defmodule OriioWeb.SignedUploadPlug do
  @moduledoc """
  Plug to check for an signed upload auth token. It extracts the token from the authroizatin header and verifies it is a valid token.
  """

  import Plug.Conn

  import Phoenix.Controller, only: [put_view: 2, render: 3]

  alias Oriio.SignedUploads

  require Logger

  @behaviour Plug

  @impl Plug
  def init(opts) do
    opts
  end

  @impl Plug
  def call(conn, _opts) do
    token =
      conn
      |> fetch_query_params()
      |> Map.get(:query_params)
      |> Map.get("token")

    with {:ok, payload} <- SignedUploads.verify_token(token) do
      assign(conn, :signed_upload_id, payload.id)
    else
      nil ->
        send_bad_request_resp(conn, "token missing")

      {:error, :signed_upload_expired} ->
        send_bad_request_resp(conn, "signed upload expired")

      {:error, :signed_upload_already_in_use} ->
        send_bad_request_resp(conn, "signed upload already in use")

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
