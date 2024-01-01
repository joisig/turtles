# Copyright (c) 2024 Jói Sigurdsson. All rights reserved.
# Licensed under AGPL, see LICENSE
defmodule HueDiscovery do
  require Logger

  def get_cached_value() do
    case Configs.get("hue_ip_string") do
      %{"value" => value} -> value
      _ -> nil
    end
  end

  def put_cached_value(val) do
    Configs.set("hue_ip_string", %{"value" => val})
  end

  def discover() do
    # This returns the last cached value if available, otherwise
    # does discovery before returning.
    #
    # The idea is to return a value very quickly but do discovery
    # in the background so that if we get an error talking to the
    # gateway because discovery was out of date, then hopefully the
    # very next request will work.
    case get_cached_value() do
      nil ->
        put_cached_value(discover_impl(nil, 15000))
      val ->
        Task.start(fn -> put_cached_value(discover_impl(val)) end)
        val
    end
  end

  def discover_impl(first_check_url \\ nil, timeout \\ 5_000)
  def discover_impl(nil, timeout) do
    # There seems to be a rate limit implemented by the Hue bridge
    # on the SSDP discovery; it will start to fail if you do it
    # 10 times or so within a span of a few seconds, at which point
    # you need to wait for a while.
    #
    # For that reason, if we have a cached IP address, we'll check
    # if we can retrieve the discovery XML file at the old IP
    # (see the non-nil case below this function body) before actually
    # doing discovery via SSDP.
    Logger.info("Initiating SSDP discovery.")

    {:ok, socket} = :gen_udp.open(0, [:binary, active: true, reuseaddr: true])

    payload = [
      "M-SEARCH * HTTP/1.1",
      "HOST: 239.255.255.250:1900",
      "MAN: ssdp:discover",
      "MX: 10",
      "ST: ssdp:all"
    ]

    # Join the payload parts with newline and convert to a binary data packet
    packet = Enum.join(payload, "\r\n") <> "\r\n\r\n"

    # Send the packet
    :ok = :gen_udp.send(socket, '239.255.255.250', 1900, packet)

    # Here we start the loop to receive messages within a receive block
    receive_messages(socket, timeout)
  end
  def discover_impl(first_check_ip, timeout) when is_binary(first_check_ip) do
    case HTTPoison.get("http://#{first_check_ip}/description.xml", [], timeout: timeout, recv_timeout: timeout) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        if String.contains?(body, "<modelName>Philips hue bridge") do
          first_check_ip
        else
          Logger.info "Found description.xml at #{first_check_ip} but does not look like a Philips Hue bridge. #{inspect body}"
          discover_impl(nil, timeout)
        end
      _ ->
        # Couldn't retrieve the description document, IP address must be wrong.
        Logger.info "No description.xml found at last-known bridge IP #{first_check_ip}, doing SSDP discovery."
        discover_impl(nil, timeout)
    end
  end

  defp receive_messages(socket, timeout) do
    receive do
      {:udp, ^socket, _hue_ip, _port, message} ->
        case parse_info(message) do
          {:ok, ip_string, true} ->
            :gen_udp.close(socket)
            ip_string
          _ ->
            receive_messages(socket, timeout)
        end
    after
      timeout ->
        :gen_udp.close(socket)
        {:error, :timeout}
    end
  end

  def parse_info(input) do
    # Split the string input by newline to handle the lines separately
    lines = String.split(input, "\n")

    # Use pattern matching and comprehensions to find LOCATION and SERVER lines
    location_line = Enum.find(lines, &String.starts_with?(&1, "LOCATION:"))
    server_line = Enum.find(lines, &String.starts_with?(&1, "SERVER:"))

    case {location_line, server_line} do
      # If LOCATION line is present, parse the IP address
      {location, _} when not is_nil(location) ->
        # Use a Regular Expression to find the IP address in the location line
        regex = ~r/http:\/\/(?<ip_address>[0-9\.]+)/
        [match] = Regex.run(regex, location, capture: :all_but_first)

        # Check if the SERVER line contains "Hue/"
        hue_present = server_line |> String.contains?("Hue/")

        # Return both the IP address and the boolean indicating the presence of "Hue/"
        {:ok, match, hue_present}

      # If LOCATION line isn't present, or we don't find an IP, return an error tuple
      _ ->
        {:error, "Required information not found"}
    end
  end
end
