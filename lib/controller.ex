defmodule Controller do
  def dimmer_by_name(name) do
    {^name, val} = :lists.keyfind(name, 1, Application.get_env(:turtles, :dimmers))
    val
  end

  def dimmer_on(device, brightness \\ 100)
  def dimmer_on(device, brightness) when is_binary(device), do: dimmer_on(dimmer_by_name(device), brightness)
  def dimmer_on(%{type: :shelly} = device, brightness) do
    params = URI.encode_query([{"turn", "on"}, {"brightness", brightness}])
    HTTPoison.get!("http://" <> device.ip <> "/light/0?" <> params)
  end
  def dimmer_on(%{type: :hue} = device, brightness) do
    params = Jason.encode!(%{"on" => true, "bri" => round(254 * brightness / 100)})
    url = get_hue_light_url(device) <> "/state"
    HTTPoison.put!(url, params)
  end

  def dimmer_off(device) when is_binary(device), do: dimmer_off(dimmer_by_name(device))
  def dimmer_off(%{type: :shelly} = device) do
    params = URI.encode_query([{"turn", "off"}])
    HTTPoison.get!("http://" <> device.ip <> "/light/0?" <> params)
  end
  def dimmer_off(%{type: :hue} = device) do
    params = Jason.encode!(%{"on" => false})
    url = get_hue_light_url(device) <> "/state"
    HTTPoison.put!(url, params)
  end

  def dimmer_state(device) when is_binary(device), do: dimmer_state(dimmer_by_name(device))
  def dimmer_state(%{type: :shelly} = device) do
    %{"ison" => is_on, "brightness" => brightness} = HTTPoison.get!(
      "http://" <> device.ip <> "/light/0").body
    |> Jason.decode!()
    {is_on, brightness}
  end
  def dimmer_state(%{type: :hue, bridge: bridge_id, unique_id: unique_id}) do
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

    light_api_key = Enum.filter(lights, fn {api_key, val} ->
      case val do
        %{"uniqueid" => ^unique_id} -> true
        _ -> false
      end
    end)
    |> Enum.at(0)
    |> elem(0)

    "http://" <> bridge.ip <> "/api/" <> bridge.username <> "/lights/" <> light_api_key
  end
end
