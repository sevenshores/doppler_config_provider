defmodule DopplerConfigProvider.HTTPClient do
  @moduledoc """
  HTTP client behaviour.
  """

  @type url :: String.t()
  @type headers :: [{String.t(), String.t()}]
  @type response :: %{status_code: pos_integer(), body: binary()}

  @callback request(url(), headers()) :: {:ok, response()} | {:error, any()}
end
