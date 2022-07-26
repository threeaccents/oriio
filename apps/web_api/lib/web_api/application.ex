defmodule WebApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias WebApi.Endpoint

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      WebApi.Telemetry,
      # Start the Endpoint (http/https)
      WebApi.Endpoint
      # Start a worker by calling: WebApi.Worker.start_link(arg)
      # {WebApi.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WebApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end
end
