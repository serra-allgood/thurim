# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :thurim, :matrix,
  auth_flows: [
    %{stages: ["m.login.dummy"]},
    %{stages: ["m.login.password"]}
  ],
  domain: "localhost",
  homeserver_url: "https://localhost:4001",
  identity_server_url: "https://matrix.org"

config :thurim, ThurimWeb.AuthSessionCache,
  gc_interval: 60 * 60 * 10 # 10 minutes

config :thurim, Thurim.AccessToken.AccessTokenCache,
  gc_interval: 86_400 # 24 hrs

config :thurim,
  ecto_repos: [Thurim.Repo],
  generators: [binary_id: true]

# Configures the endpoint
config :thurim, ThurimWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "HFselKcyTQskoEG2FaIjyDDIESOu1ZSXf1rEeQyG66cl3P1UdjxuORd0qTiQk4jM",
  render_errors: [view: ThurimWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Thurim.PubSub,
  live_view: [signing_salt: "EJbWbKzT"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
