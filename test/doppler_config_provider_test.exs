defmodule DopplerConfigProviderTest do
  use ExUnit.Case
  doctest DopplerConfigProvider

  test "greets the world" do
    assert DopplerConfigProvider.hello() == :world
  end
end
