defmodule ThurimApiHelpersTest do
  use ExUnit.Case
  doctest ThurimApiHelpers

  test "greets the world" do
    assert ThurimApiHelpers.hello() == :world
  end
end
