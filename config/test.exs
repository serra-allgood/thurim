import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :thurim_gateway, ThurimGateway.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "QMlkd9NdY3djpuCtRivBBflymtWkVVLgVz0CKzpPc2OAN8bgrIuU51SF5H9wKnFx",
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
