defmodule ThurimMedia.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ThurimMedia.Telemetry,
      # Start a worker by calling: ThurimMedia.Worker.start_link(arg)
      # {ThurimMedia.Worker, arg},
      # Start to serve requests, typically the last entry
      ThurimMedia.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ThurimMedia.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ThurimMedia.Endpoint.config_change(changed, removed)
    :ok
  end
end
