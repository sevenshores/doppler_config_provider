defmodule DopplerConfigProvider.HTTPClient do
  @moduledoc """
  HTTP client behaviour. Any HTTP client module supplied to this config provider
  must implement a `request/2` function that returns either `:ok` or `:error`
  tuples matching the specified `type`s.
  """

  @type url :: String.t()
  @type headers :: [{String.t(), String.t()}]
  @type response :: %{status_code: pos_integer(), body: binary()}

  @callback request(:get, url(), headers()) :: {:ok, response()} | {:error, any()}
end
