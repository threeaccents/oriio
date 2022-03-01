defmodule MahiWeb.SignedUrlController do
  use MahiWeb, :controller

  action_fallback MahiWeb.FallbackController

  plug MahiWeb.AuthPlug

  def create(conn, _params) do
    json(conn, %{hello: "world"})
  end
end
