defmodule HelloAgonesTest do
  use ExUnit.Case
  doctest HelloAgones

  test "greets the world" do
    assert HelloAgones.hello() == :world
  end
end
