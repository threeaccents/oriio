defmodule MahiWeb.Pipeline do
  @moduledoc false

  use MahiWeb, :router

  import Plug.BasicAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {MahiWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug ProperCase.Plug.SnakeCaseParams
  end

  pipeline :multipart do
    plug :accepts, ["multipart"]
  end

  pipeline :file_delivery do
    plug :accepts, ["*"]
  end

  pipeline :admins_only do
    plug :basic_auth, username: "admin", password: "mahiAdmin13!"
  end
end
