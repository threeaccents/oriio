defmodule MahiWeb.ParseTokenPlug do
  use MahiWeb, :plug

  @impl Plug
  def init(_params) do
  end

  @impl Plug
  def call(%{query_params: %{token: auth_token}} = conn, _params) when is_binary(auth_token) do
    assign(conn, :token, auth_token)
  end

  def call(conn, _), do: conn
end
