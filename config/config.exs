# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :thurim, :matrix,
  auth_flows: [
    # %{stages: ["m.login.dummy"]},
    %{stages: ["m.login.password"]}
  ],
  auth_flow_types: [%{"type" => "m.login.password"}],
  default_room_version: "9",
  supported_room_versions: ~w(9),
  domain: "localhost",
  homeserver_url: "https://localhost:4001"

config :thurim, Thurim.Sync.SyncCache,
  # When using :shards as backend
  # backend: :shards,
  # GC interval for pushing new generation: 12 hrs
  gc_interval: :timer.hours(24),
  # Max 1 million entries in cache
  max_size: 1_000_000,
  # Max 2 GB of memory
  allocated_memory: 2_000_000_000,
  # GC min timeout: 10 sec
  gc_cleanup_min_timeout: :timer.seconds(10),
  # GC min timeout: 10 min
  gc_cleanup_max_timeout: :timer.minutes(10)

config :thurim, ThurimWeb.AuthSessionCache,
  # 10 minutes
  gc_interval: :timer.minutes(10),
  # Max 1 million entries in cache
  max_size: 1_000_000,
  # Max 2 GB of memory
  allocated_memory: 2_000_000_000,
  # GC min timeout: 10 sec
  gc_cleanup_min_timeout: :timer.seconds(10),
  # GC min timeout: 10 min
  gc_cleanup_max_timeout: :timer.minutes(10)

config :thurim, Thurim.AccessToken.AccessTokenCache,
  # 24 hrs
  gc_interval: :timer.hours(24),
  # Max 1 million entries in cache
  max_size: 1_000_000,
  # Max 2 GB of memory
  allocated_memory: 2_000_000_000,
  # GC min timeout: 10 sec
  gc_cleanup_min_timeout: :timer.seconds(10),
  # GC min timeout: 10 min
  gc_cleanup_max_timeout: :timer.minutes(10)

config :thurim,
  ecto_repos: [Thurim.Repo],
  generators: [binary_id: true]

# Configures the endpoint
config :thurim, ThurimWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: ThurimWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Thurim.PubSub,
  live_view: [signing_salt: "Y9mMCo0T"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :thurim, Thurim.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
