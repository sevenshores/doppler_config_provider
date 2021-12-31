defmodule DopplerConfigProvider.JSONDecoder do
  @moduledoc """
  JSON decoder behaviour.
  """

  @callback decode!(String.t()) :: map() | no_return()
end
