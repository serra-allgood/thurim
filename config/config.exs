# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

config :thurim_media,
  ecto_repos: [ThurimCore.Repo],
  generators: [context_app: false]

# Configures the endpoint
config :thurim_media, ThurimMedia.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: ThurimMedia.ErrorJSON],
    layout: false
  ],
  pubsub_server: ThurimMedia.PubSub,
  live_view: [signing_salt: "ShctnzrA"]

config :thurim_appservice,
  ecto_repos: [ThurimCore.Repo],
  generators: [context_app: false]

# Configures the endpoint
config :thurim_appservice, ThurimAppservice.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: ThurimAppservice.ErrorJSON],
    layout: false
  ],
  pubsub_server: ThurimAppservice.PubSub,
  live_view: [signing_salt: "HbAKtYpT"]

config :thurim_federation,
  ecto_repos: [ThurimCore.Repo],
  generators: [context_app: false]

# Configures the endpoint
config :thurim_federation, ThurimFederation.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: ThurimFederation.ErrorJSON],
    layout: false
  ],
  pubsub_server: ThurimFederation.PubSub,
  live_view: [signing_salt: "SuTRoGfp"]

config :thurim_client_api,
  ecto_repos: [ThurimCore.Repo],
  generators: [context_app: false]

# Configures the endpoint
config :thurim_client_api, ThurimClientApi.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: ThurimClientApi.ErrorJSON],
    layout: false
  ],
  pubsub_server: ThurimClientApi.PubSub,
  live_view: [signing_salt: "Tivk3mKJ"]

# Configure Mix tasks and generators
config :thurim_core,
  ecto_repos: [ThurimCore.Repo]

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
# config :thurim_core, ThurimCore.Mailer, adapter: Swoosh.Adapters.Local

# Sample configuration:
#
#     config :logger, :default_handler,
#       level: :info
#
#     config :logger, :default_formatter,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]
#

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
