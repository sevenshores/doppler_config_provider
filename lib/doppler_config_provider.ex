defmodule DopplerConfigProvider do
  @moduledoc """
  `DopplerConfigProvider` fetches the config from Doppler and merges it with
  your application config at system boot.
  """
  @behaviour Config.Provider

  require Logger

  @type service_token :: String.t()

  @type http_module :: module() | {atom(), module()}

  @type json_module :: module() | {atom(), module()}

  @type mappings ::
          %{optional(String.t()) => {atom(), atom()}}
          | %{optional(String.t()) => {atom(), module(), atom()}}

  @type options :: [
          {:service_token, service_token()}
          | {:http_module, http_module()}
          | {:json_module, json_module()}
          | {:mappings, mappings()}
        ]

  @opaque map_options :: %{
            service_token: service_token(),
            http_module: http_module(),
            json_module: json_module(),
            mappings: mappings()
          }

  @doppler_url "https://api.doppler.com/v3/configs/config/secrets/download"

  @doc """
  Invoked when initializing the config provider.

  A config provider is typically initialized on the machine where the system is
  assembled and not on the target machine. The `init/1` callback is useful to
  verify the arguments given to the provider and prepare the state that will be
  given to `load/2`.
  """
  @impl Config.Provider
  @spec init(options()) :: options()
  def init(opts) when is_list(opts), do: opts

  @doc """
  Loads configuration (typically during system boot).

  Note that `load/2` is typically invoked very early in the boot process.
  """
  @impl Config.Provider
  def load(config, opts) do
    Logger.info("[DopplerConfigProvider] Loading Doppler config...")
    opts = merge_opts_to_map(opts)
    doppler_config = fetch_doppler_config!(opts)

    Enum.reduce(doppler_config, config, fn {key, value}, acc ->
      case Map.get(opts.mappings, key) do
        {app, module, key} ->
          Config.Reader.merge(acc, [{app, {module, {key, value}}}])

        {app, key} ->
          Config.Reader.merge(acc, [{app, {key, value}}])

        nil ->
          Logger.warn("[DopplerConfigProvider] Unhandled doppler config `#{key}`")
          acc
      end
    end)
  end

  @doc "Perform the request to doppler with the provided HTTP module."
  @spec fetch_doppler_config!(map_options(), String.t()) :: map() | no_return()
  def fetch_doppler_config!(opts, url \\ @doppler_url)

  def fetch_doppler_config!(%{http_module: {http_app, http_module}} = opts, url) do
    {:ok, _} = Application.ensure_all_started(http_app)
    fetch_doppler_config!(%{opts | http_module: http_module}, url)
  end

  def fetch_doppler_config!(opts, url) do
    headers =
      opts.service_token
      |> Kernel.<>(":")
      |> Base.encode64()
      |> then(&["authorization", "Basic " <> &1])

    case opts.http_module.request(:get, url, headers, "", []) do
      {:ok, %{status_code: 200, body: body}} -> json_decode!(body, opts)
      error -> raise "Unable to fetch Doppler config: #{inspect(error)}"
    end
  end

  @doc "Perform the JSON decoding with the provided JSON module."
  @spec json_decode!(String.t(), map_options()) :: map() | no_return()
  def json_decode!(body, %{json_module: {json_app, json_module}} = opts) do
    {:ok, _} = Application.ensure_all_started(json_app)
    json_decode!(body, %{opts | json_module: json_module})
  end

  def json_decode!(body, opts) do
    opts.json_module.decode!(body)
  end

  # Get the HTTP module from the opts or provide a default (if the dependency exists).
  # Raises an error if none provided and optional dependencies aren't installed.
  defp http_module_from_opts(opts) do
    case Keyword.get(opts, :http_module) do
      nil ->
        if Code.ensure_loaded?(Mojito) do
          {:mojito, Mojito}
        else
          raise ArgumentError,
            message: "Must include :http_module or add :mojito or :finch as a dependency"
        end

      http_module ->
        http_module
    end
  end

  # Get the JSON module from the opts or provide a default (if the dependency exists).
  # Raises an error if none provided and optional dependencies aren't installed.
  defp json_module_from_opts(opts) do
    case Keyword.get(opts, :json_module) do
      nil ->
        cond do
          Code.ensure_loaded?(Jason) ->
            {:jason, Jason}

          Code.ensure_loaded?(Poison) ->
            {:poison, Poison}

          true ->
            raise ArgumentError,
              message: "Must include :json_module or add :jason or :poison as a dependency"
        end

      json_module ->
        json_module
    end
  end

  defp merge_opts_to_map(opts) do
    :doppler_config_provider
    |> Application.get_all_env()
    |> Keyword.merge(opts)
    |> Enum.into(%{})
    |> Map.update(:http_module, nil, &http_module_from_opts/1)
    |> Map.update(:json_module, nil, &json_module_from_opts/1)
  end
end
