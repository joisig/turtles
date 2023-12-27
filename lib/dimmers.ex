defmodule Dimmers do
  def by_name(name) do
    {^name, val} = :lists.keyfind(name, 1, Application.get_env(:turtles, :dimmers))
    val
  end

  def on(device, brightness \\ 100)
  def on(device, brightness) when is_binary(device), do: on(by_name(device), brightness)
  def on(%{type: :shelly} = device, brightness) do
    params = URI.encode_query([{"turn", "on"}, {"brightness", brightness}])
    HTTPoison.get!("http://" <> device.ip <> "/light/0?" <> params)
  end
  def on(%{type: :hue} = device, brightness) do
    params = Jason.encode!(%{"on" => true, "bri" => round(254 * brightness / 100)})
    url = get_hue_light_url(device) <> "/state"
    HTTPoison.put!(url, params)
  end

  def off(device) when is_binary(device), do: off(by_name(device))
  def off(%{type: :shelly} = device) do
    params = URI.encode_query([{"turn", "off"}])
    HTTPoison.get!("http://" <> device.ip <> "/light/0?" <> params)
  end
  def off(%{type: :hue} = device) do
    params = Jason.encode!(%{"on" => false})
    url = get_hue_light_url(device) <> "/state"
    HTTPoison.put!(url, params)
  end

  def state(device) when is_binary(device), do: state(by_name(device))
  def state(%{type: :shelly} = device) do
    %{"ison" => is_on, "brightness" => brightness} = HTTPoison.get!(
      "http://" <> device.ip <> "/light/0").body
    |> Jason.decode!()
    {is_on, brightness}
  end
  def state(%{type: :hue, bridge: bridge_id, unique_id: unique_id}) do
    bridge = Application.get_env(:turtles, :bridges)[bridge_id]
    [%{"on" => is_on, "bri" => brightness_out_of_254}] = get_bridge_lights(bridge)
    |> Enum.flat_map(fn {_, val} ->
      case val do
        %{"uniqueid" => ^unique_id} -> [val["state"]]
        _ -> []
      end
    end)
    {is_on, round(brightness_out_of_254 * 100 / 254)}
  end

  def get_bridge_lights(%{ip: ip, username: username} = _bridge) do
    HTTPoison.get!("http://" <> ip <> "/api/" <> username <> "/lights").body
    |> Jason.decode!()
  end

  def get_hue_light_url(%{type: :hue, bridge: bridge_id, unique_id: unique_id}) do
    bridge = Application.get_env(:turtles, :bridges)[bridge_id]
    lights = get_bridge_lights(bridge)

    [light_api_key] = Enum.flat_map(lights, fn {api_key, val} ->
      case val do
        %{"uniqueid" => ^unique_id} -> [api_key]
        _ -> []
      end
    end)

    "http://" <> bridge.ip <> "/api/" <> bridge.username <> "/lights/" <> light_api_key
  end
end

# For Hue auth and API, see:
# https://developers.meethue.com/develop/get-started-2/
# https://www.burgestrand.se/hue-api/api/auth/registration/
# https://www.burgestrand.se/hue-api/

# For Shelly APIs, see this and related:
# https://shelly-api-docs.shelly.cloud/gen1/#shelly-dimmer-1-2-light-0

# For both types of lights, to KISS, I gave all the lights and the Hue
# bridge a static IP address and then keep the IP addresses and the Zigbee lights'
# unique ID in the configuration file (see tconfig.secret.exs).
