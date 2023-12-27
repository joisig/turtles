defmodule Turtles.Repo do
  use Ecto.Repo,
    otp_app: :turtles,
    adapter: Ecto.Adapters.SQLite3
end
