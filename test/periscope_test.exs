defmodule PeriscopeTest do
  use ExUnit.Case
  doctest Periscope

  test "greets the world" do
    assert Periscope.hello() == :world
  end
end
