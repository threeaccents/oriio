defmodule OriioWeb.AuthPlug do
  import Plug.Conn

  import Phoenix.Controller, only: [put_view: 2, render: 3]

  require Logger

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         :ok <- verify_token(token) do
      conn
    else
      [] ->
        send_bad_request_resp(conn, "bearer token missing")

      {:error, reason} ->
        Logger.warn("failed to verify token: #{inspect(reason)}")
        send_unauthorized_resp(conn)
    end
  end

  defp verify_token(token) do
    if token == auth_secret_key(), do: :ok, else: {:error, :invalid_auth_token}
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

  defp auth_secret_key, do: Application.get_env(:oriio_web, :auth_secret_key)
end
