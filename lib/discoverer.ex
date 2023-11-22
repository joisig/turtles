defmodule Discoverer do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def discover_now(), do: discover_now(__MODULE__)
  def discover_now(pid), do: GenServer.cast(pid, :discover_now)

  def get_devices(), do: get_devices(__MODULE__)
  def get_devices(pid), do: GenServer.call(pid, :get_devices)

  @impl true
  def init(state) do
    {:noreply, state} = handle_cast(:discover_now, state)
    {:ok, state}
  end

  @impl true
  def handle_call(:get_devices, _from, state) do
    {:reply, state, state}
  end

  def impl_check(ip, cb_fn) do
    try do
      result = HTTPoison.get("http://#{ip}/settings", [], hackney: [pool: :ping_pool, connect_timeout: 6000, recv_timeout: 8000])
      case result do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          case Jason.decode(body) do
            {:ok, result} ->
              case result do
                %{"device" => %{"mac" => mac}} ->
                  cb_fn.(mac, Map.put(result, "ip_address", ip))
                _ ->
                  :nothing_to_do
              end
            _ ->
              :nothing_to_do
          end
        _ ->
          :nothing_to_do
      end
    rescue
      _ -> :error
    end
  end

  def impl_multi_check(cb_fn) do
    ip_base = Application.fetch_env!(:turtles, :ip_base)
    Enum.map(1..255, fn ip_num ->
      spawn(fn ->
        ip = "#{ip_base}#{ip_num}"
        impl_check(ip, cb_fn)
      end)
    end)
  end

  @impl true
  def handle_cast(:discover_now, state) do
    parent = self()
    impl_multi_check(fn ip, result ->
      GenServer.cast(parent, {:update_device, ip, result})
    end)
    {:noreply, state}
  end
  def handle_cast({:update_device, ip, details}, state) do
    {:noreply, Map.put(state, ip, details)}
  end
end
