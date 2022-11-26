defmodule Thurim.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Thurim.Repo,
      # Start needed supervisors
      Thurim.CacheSupervisor,
      {Task.Supervisor, name: Thurim.SyncTaskSupervisor},
      Thurim.Federation.KeyServer,
      Thurim.Rooms.RoomServer,
      # Start the Telemetry supervisor
      ThurimWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Thurim.PubSub},
      # Start the Endpoint (http/https)
      ThurimWeb.Endpoint
      # Start a worker by calling: Thurim.Worker.start_link(arg)
      # {Thurim.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Thurim.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ThurimWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
