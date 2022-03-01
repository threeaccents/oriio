defmodule Guardian.Plug.VerifyHeader do
  import Plug.Conn

  @behaviour Plug

  @impl Plug
  def init(_) do
  end

  @impl Plug
  def call(conn, _opts) do
    case fetch_token_from_header(conn) do
      {:ok, token} ->
        assign(conn, :token, token)

      _ ->
        conn
    end
  end

  defp fetch_token_from_header(conn) do
    [header | _] = get_resp_header(conn, "authorization")

    [_, token] = String.split(header, "Bearer ")

    {:ok, token}
  end
end
