import Config

import_config "config.secret.exs"

# Above file should contain structure something like:
#config :turtles,
#  ip_base: "192.168.1.",
#  lights: [
#    %{type: "shelly", ip: "192.168.1.100", name: "1"},
#    %{type: "shelly", ip: "192.168.1.101", name: "2"},
#    %{type: "shelly", ip: "192.168.1.102", name: "3"},
#    %{type: "shelly", ip: "192.168.1.103", name: "4"},
#    %{type: "hue", bridge: "hue1", name: "light5"}
#  ],
#  bridges: [
#    %{type: "hue", ip: "192.168.1.104", name: "hue1", username: "username you got from /api on bridge"}
#  ]


# For Hue auth and API, see:
# https://developers.meethue.com/develop/get-started-2/
# https://www.burgestrand.se/hue-api/api/auth/registration/
# https://www.burgestrand.se/hue-api/
