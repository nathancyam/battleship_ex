# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :battleship,
  ecto_repos: [Battleship.Repo],
  generators: [binary_id: true]

# Configures the endpoint
config :battleship, BattleshipWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "AceBkIUKiCmJS8esLEquwj1cnnxJBiqe2Uju24IwCYQQEKofVEKQ/1HDAeZDAdRa",
  render_errors: [view: BattleshipWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Battleship.PubSub,
  live_view: [signing_salt: "yz4mym4T"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
