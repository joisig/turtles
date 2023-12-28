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
        :gen_udp.close(socket)
        IO.inspect message
        if String.contains?(message, "description.xml") do
          {:ok, new(hue_ip)}
        else
          receive_messages(socket, timeout)
        end
    after
      timeout ->
        :gen_udp.close(socket)
        {:error, :timeout}
    end
  end

  defp new(hue_ip) do
    IO.inspect hue_ip
  end
end
