defmodule TurtlesTest do
  use ExUnit.Case
  doctest Turtles

  test "greets the world" do
    assert Turtles.hello() == :world
  end
end
