if Code.ensure_loaded?(Mojito) do
  defmodule DopplerConfigProvider.HTTPClient.MojitoClient do
    @moduledoc false

    @behaviour DopplerConfigProvider.HTTPClient

    @impl DopplerConfigProvider.HTTPClient
    def request(url, headers) do
      Mojito.request(:get, url, headers)
    end
  end
end
