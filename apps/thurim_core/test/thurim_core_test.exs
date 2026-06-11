defmodule ThurimCoreTest do
  use ExUnit.Case
  doctest ThurimCore

  test "greets the world" do
    assert ThurimCore.hello() == :world
  end
end
