defmodule DopplerConfigProvider.JSONDecoder do
  @moduledoc """
  JSON decoder behaviour. Any JSON library supplied to this config provider must
  implement a `decode!/1` function that returns the decoded JSON as a map, or
  raise an error if it cannot.
  """

  @callback decode!(String.t()) :: map() | no_return()
end
