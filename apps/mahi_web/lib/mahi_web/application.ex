defmodule MahiWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias MahiWeb.Endpoint

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      MahiWeb.Telemetry,
      # Start the Endpoint (http/https)
      MahiWeb.Endpoint
      # Start a worker by calling: MahiWeb.Worker.start_link(arg)
      # {MahiWeb.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MahiWeb.Supervisor]
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
