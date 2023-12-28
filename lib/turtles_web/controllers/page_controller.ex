defmodule TurtlesWeb.PageController do
  use TurtlesWeb, :controller

  def home(conn, _params) do
    dimmers = Dimmers.all_states()
    |> Enum.map(fn {name, {is_on, brightness}} ->
      %{name: name, is_on: is_on, brightness: brightness}
    end)

    render(conn,
      :home,
      layout: false,
      dimmers: dimmers)
  end

  def set_light_state(conn, %{"dimmer_name" => dimmer_name, "is_on" => is_on, "brightness" => brightness}) do
    Dimmers.set_state(dimmer_name, is_on, brightness)
    conn |> send_resp(200, "ok")
  end
end
