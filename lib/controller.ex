defmodule Controller do
  def dimmer_on(device, brightness \\ 100) do
    params = URI.encode_query([{"turn", "on"}, {"brightness", brightness}])
    HTTPoison.get!("http://" <> device["ip_address"] <> "/light/0?" <> params)
  end

  def dimmer_off(device) do
    params = URI.encode_query([{"turn", "off"}])
    HTTPoison.get!("http://" <> device["ip_address"] <> "/light/0?" <> params)
  end
end
