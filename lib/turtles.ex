defmodule Turtles do
  @moduledoc """
  Shelly dimmers can be turned on/off and brightness changed, quite easily.

  ➜  turtles curl http://192.168.1.146/light/0\?turn\=on
  ➜  turtles curl http://192.168.1.146/light/0\?turn\=off
  ➜  turtles curl http://192.168.1.146/light/0\?turn\=on\&brightness\=70
  """

  use Application

  @impl true
  def start(_type, _args) do
    #:ok = :hackney_pool.start_pool(:ping_pool, [timeout: 2000, max_connections: 400])

    children = [
    #  Discoverer
    ]

    opts = [strategy: :one_for_one, name: C.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def foo() do
    Application.fetch_env(:turtles, :foo)
  end
end
