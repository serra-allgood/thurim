defmodule ThurimApiHelpers.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: ThurimApiHelpers.Worker.start_link(arg)
      # {ThurimApiHelpers.Worker, arg}
      {ThurimApiHelpers.RateLimit,
       [clean_period: :timer.minutes(1), key_older_than: :timer.hours(24)]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ThurimApiHelpers.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
