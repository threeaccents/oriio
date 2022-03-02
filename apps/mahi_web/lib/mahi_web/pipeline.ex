defmodule OriioWeb.Pipeline do
  @moduledoc false

  use OriioWeb, :router

  import Plug.BasicAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {OriioWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug OriioWeb.AuthPlug
    plug :accepts, ["json"]
    plug ProperCase.Plug.SnakeCaseParams
  end

  pipeline :multipart do
    plug OriioWeb.AuthPlug
    plug :accepts, ["multipart"]
  end

  pipeline :signed_upload do
    plug :accepts, ["multipart"]
  end

  pipeline :file_delivery do
    plug :accepts, ["*"]
  end

  pipeline :admins_only do
    plug :basic_auth, username: "admin", password: "oriioAdmin13!"
  end
end
