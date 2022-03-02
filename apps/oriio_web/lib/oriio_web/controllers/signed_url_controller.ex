defmodule OriioWeb.SignedUrlController do
  use OriioWeb, :controller

  action_fallback OriioWeb.FallbackController

  plug OriioWeb.AuthPlug

  def create(conn, _params) do
    json(conn, %{hello: "world"})
  end
end
