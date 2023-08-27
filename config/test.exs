import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :paprica, Paprica.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "paprica_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :paprica, PapricaWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "GBqt8KBhCx0yAJWTcB4LXuemGPtk2jEyTp0D1MefICeY1L7aNByLFdUCvnL0A/SZ",
  server: false

# In test we don't send emails.
config :paprica, Paprica.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
