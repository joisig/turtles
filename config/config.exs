# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :turtles,
  ecto_repos: [Turtles.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :turtles, TurtlesWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [html: TurtlesWeb.ErrorHTML, json: TurtlesWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Turtles.PubSub,
  live_view: [signing_salt: "AZ4oqRvZ"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# This imports the secret configuration for your lighs and bridge; see
# example of contents of this file right below.
import_config "tconfig.secret.exs"

# # Example tconfig.secret.exs contents:
#
# config :turtles,
#   zones: [
#     "Foyer",
#     "Kitchen"
#   ],
#   dimmers: [
#     {"foyerrecessed",
#       %{name: "Forstofa inngangur", type: :shelly, zone: "Foyer", ip: "192.168.1.90"}},
#     {"foyerindirectled",
#       # Hue device unique IDs can be found at
#       # http://{ip address of bridge}/api/{Hue bridge username}/lights
#       %{name: "Foyer indirect LEDs", type: :hue, zone: "Foyer", bridge: :hue1, unique_id: "04:11:84:ff:13:43:75:a3-01"}},
#
#     {"kitchenbenches",
#       %{name: "Kitchen worktops", type: :shelly, zone: "Kitchen", ip: "192.168.1.96"}},
#     {"kitchenisland",
#       %{name: "Kitchen island", type: :hue, zone: "Kitchen", bridge: :hue1, unique_id: "03:11:84:ff:13:12:75:a1-03"}},
#   ],
#   bridges: %{
#     # For details on getting the username, see
#     # https://www.burgestrand.se/hue-api/api/auth/registration/
#     #
#     # The unique_id can be found at http://{ip address of bridge}/description.xml
#     # under the <serialNumber> key.
#     hue1: %{type: :hue, unique_id: "abcdef01234", username: "HUEBRIDGEUSERNAME"}
#   }


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
