import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :mahi, Mahi.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "mahi_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mahi_web, MahiWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "UpNuqSSvGSAnKUS5lfe+Do73q+UKdeTnl8m9Lrq0PkfVK5F2GZvOehtz+wH1kcbr",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# In test we don't send emails.
config :mahi, Mahi.Mailer, adapter: Swoosh.Adapters.Test

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
