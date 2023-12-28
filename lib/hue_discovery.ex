defmodule HueDiscovery do
  def discover(timeout \\ 5_000) do
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

  defp receive_messages(socket, timeout) do
    receive do
      {:udp, ^socket, hue_ip, _port, message} ->
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
