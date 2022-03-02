defmodule OriioWeb.ParseHeaderTokenPlug do
  use OriioWeb, :plug

  @impl Plug
  def init(_) do
  end

  @impl Plug
  def call(conn, _opts) do
    assign(conn, :token, fetch_token_from_header(conn))
  end

  defp fetch_token_from_header(conn) do
    [header | _] = get_resp_header(conn, "authorization")

    # error handleing later
    [_, token] = String.split(header, "Bearer ")

    token
  end
end
