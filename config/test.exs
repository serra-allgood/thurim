import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :thurim_media, ThurimMedia.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "qYWcdLm9MvpqHuoF+SzjTGB5hrDXeO4vubqRD5w9rYHLzLUEgrWN+K8cHByYBtyc",
  server: false

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :thurim_appservice, ThurimAppservice.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "u0vJkO0n0S6c6UwNQoL5D0QHCz0I0sF1sVGc/ggmUpfTfOF4medoTIvZF0tRIKUO",
  server: false

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :thurim_federation, ThurimFederation.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "ZbWLdKq+5QjO4LmirLlZK9OMhzpD3Hur/u1sBf/6TDzV8xlg5zQy/A3W1Ht2RSBP",
  server: false

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :thurim_client_api, ThurimClientApi.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "Gav5r4p36qTain8P2mOA9D7OV+UTNxt9++8xiHK8fL0mJ+5Pkhszun+PuG3xM//s",
  server: false

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :thurim_core, ThurimCore.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "thurim_core_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :thurim_client_api, ThurimClientApi.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "tR6hBSqEuU1eb1a+PpWwFDUt4RxVag/hQv44RTAr7TaNK1eRXS9NV/+GYjFTumd7",
  server: false

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :thurim_media, ThurimMedia.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "Ka3Zc9kCFR9ighzHoAYqj9LifRM7USBWvbE2tnKL14TZnRgP84DjaUNHPZPChWM1",
  server: false

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :thurim_appservice, ThurimAppservice.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "C3MG32Z4elKeu9mMt6ZVqMAHoLZDK4XXNTgH8Lix91zCyBVa0SWz/4/TuU1IPUQD",
  server: false

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :thurim_federation, ThurimFederation.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "mtt1J+uRy44NFJZ+2sArcVzSxT+Ku0jRBlZpMiYXwBOpIopBRsIrXhRtoSVGwmDD",
  server: false

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :thurim_client_api, ThurimClientApi.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "F5o1wRExcEjAr9dAl/EDLKgvna364cego78SU/XviTMyauDf2X0fWnwAIC/+Vu+Y",
  server: false

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :thurim_federation, ThurimFederation.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "MolXb6a+Byvz93+46/Gbw1BLbFjjab2S8/fU/hBXILM6viWYB7gh23OZMxjuq4jS",
  server: false

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :thurim_client_api, ThurimClientApi.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "umNz2oKAox/UBCZFF87cZ7AClQtxWAIYNBUnz38MUQ3URrr67SmJ4z/FghzXN+G8",
  server: false
