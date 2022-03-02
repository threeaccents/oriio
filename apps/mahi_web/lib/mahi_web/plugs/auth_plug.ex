defmodule MahiWeb.AuthPlug do
  import Plug.Conn

  alias Mahi.SignedUrl
  require Logger

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         :ok <- SignedUrl.verify_token(token) do
      conn
    else
      _error ->
        conn
        |> put_status(:unauthorized)
        |> Phoenix.Controller.put_view(MahiWeb.ErrorView)
        |> Phoenix.Controller.render("error.json", {:error, :unauthorized})
        |> halt()
    end
  end
end
