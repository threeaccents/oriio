defmodule WebApi.Router do
  use WebApi, :router

  import WebApi.Pipeline

  @dialyzer {:no_return, call: 2}

  scope "/", WebApi do
    pipe_through :api

    post "/chunk_uploads", UploadController, :new_chunk_upload
    post "/chunk_uploads/:upload_id", UploadController, :complete_chunk_upload
    post "/signed_uploads", SignedUploadController, :create
  end

  scope "/", WebApi do
    pipe_through :multipart

    post "/append_chunk", UploadController, :append_chunk
    post "/uploads", UploadController, :upload
  end

  scope "/signed_uploads", WebApi do
    pipe_through :signed_upload_api

    post "/chunk_uploads", SignedUploadController, :new_chunk_upload
    post "/chunk_uploads/:upload_id", SignedUploadController, :complete_chunk_upload
  end

  scope "/signed_uploads", WebApi do
    pipe_through :signed_upload_multipart

    post "/append_chunk", UploadController, :append_chunk
    post "/uploads", SignedUploadController, :upload
  end

  scope "/", WebApi do
    pipe_through :file_delivery

    get "/:timestamp/:file_name", FileDeliveryController, :serve_file
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test, :prod] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :admins_only

      live_dashboard "/dashboard", metrics: WebApi.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
