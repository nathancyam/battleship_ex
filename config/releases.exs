import Config

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :battleship, Battleship.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "2")

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :new_relic_agent,
  app_name: System.get_env("NEW_RELIC_APP_NAME"),
  license_key: System.get_env("NEW_RELIC_LICENSE_KEY")

config :battleship, BattleshipWeb.Endpoint,
  http: [
    port: {:system, "PORT"},
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base,
  server: true
