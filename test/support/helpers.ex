defmodule Support.Helpers do
  import ExUnit.Assertions

  def expect_to_match(result, expected) do
    result = result |> String.strip |> String.split("\n")
    expected = expected |> String.strip |> String.split("\n")
    assert result == expected
  end

end
