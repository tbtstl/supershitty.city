# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :supershittycity,
  ecto_repos: [Supershittycity.Repo]

# Configures the endpoint
config :supershittycity, SupershittycityWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "7xrSG2XCsfY8hoRss2GGKx8UtXgDqt8LJIFsRmknPGv/R/qEWvfIcM2EzBLEeGgN",
  render_errors: [view: SupershittycityWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Supershittycity.PubSub, adapter: Phoenix.PubSub.PG2]

config :supershittycity, Supershittycity.Scheduler,
  jobs: [
    # Every minute
    {"* * * * *", {Supershittycity.Application, :fetch_poop, []}}
  ]


# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
