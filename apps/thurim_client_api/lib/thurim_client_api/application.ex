defmodule ThurimClientApi.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ThurimClientApi.Telemetry,
      # Start a worker by calling: ThurimClientApi.Worker.start_link(arg)
      # {ThurimClientApi.Worker, arg},
      {ThurimClientApi.RateLimit,
       [clean_period: :timer.minutes(1), key_older_than: :timer.hours(24)]},
      # Start to serve requests, typically the last entry
      ThurimClientApi.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ThurimClientApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ThurimClientApi.Endpoint.config_change(changed, removed)
    :ok
  end
end
