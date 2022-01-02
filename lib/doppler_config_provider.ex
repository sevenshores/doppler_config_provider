defmodule DopplerConfigProvider do
  @moduledoc """
  `DopplerConfigProvider` fetches the config from Doppler and merges it with
  your application config at system boot.
  """
  @behaviour Config.Provider

  require Logger

  @type service_token :: String.t()

  @type http_module :: module() | {module(), atom() | [atom()]}

  @type json_module :: module() | {module(), atom() | [atom()]}

  @type mappings :: %{required(String.t()) => [key :: term()]}

  @type options :: [
          {:service_token, service_token()}
          | {:http_module, http_module()}
          | {:json_module, json_module()}
          | {:mappings, mappings()}
        ]

  @type map_options :: %{
          service_token: service_token(),
          http_module: http_module(),
          json_module: json_module(),
          mappings: mappings()
        }

  @doppler_url "https://api.doppler.com/v3/configs/config/secrets/download"

  @doc """
  Invoked when initializing the config provider.

  Since we can pass the config through application env (config files), we can't
  really do any validation on the options here. So, it's just a pass-through.
  """
  @impl Config.Provider
  @spec init(options()) :: options()
  def init(opts) when is_list(opts), do: opts

  @doc """
  Loads configuration and is typically invoked very early in the boot process.
  """
  @impl Config.Provider
  def load(config, opts) do
    Logger.info("[DopplerConfigProvider] Loading Doppler config...")

    opts =
      config
      |> Keyword.get(:doppler_config_provider, [])
      |> merge_opts_to_map(opts)

    doppler_config =
      opts
      |> fetch_doppler_config!()
      |> Map.drop(~w(DOPPLER_CONFIG DOPPLER_ENVIRONMENT DOPPLER_PROJECT))

    Enum.reduce(doppler_config, config, fn {doppler_key, value}, acc ->
      case Map.get(opts.mappings, doppler_key) do
        nil ->
          Logger.warn("[DopplerConfigProvider] Unhandled doppler config `#{doppler_key}`")
          acc

        keys ->
          Config.Reader.merge(acc, nested_options(keys, value))
      end
    end)
  end

  # Build the nested options list for deep merging the config.
  defp nested_options([key], value), do: [{key, value}]

  defp nested_options([key | rest], value) do
    [{key, nested_options(rest, value)}]
  end

  @doc """
  Perform the request to Doppler with the provided HTTP module.
  """
  @spec fetch_doppler_config!(map_options(), String.t()) :: map() | no_return()
  def fetch_doppler_config!(opts, url \\ @doppler_url)

  def fetch_doppler_config!(%{http_module: {http_module, http_apps}} = opts, url) do
    ensure_all_started!(http_apps)
    fetch_doppler_config!(%{opts | http_module: http_module}, url)
  end

  def fetch_doppler_config!(opts, url) do
    headers = [{"authorization", "Basic " <> Base.encode64(opts.service_token <> ":")}]

    case opts.http_module.request(:get, url, headers) do
      {:ok, %{status_code: 200, body: body}} ->
        json_decode!(body, opts)

      error ->
        raise "Unable to fetch Doppler config: #{inspect(error)}"
    end
  end

  @doc """
  Perform the JSON decoding with the provided JSON module.
  """
  @spec json_decode!(String.t(), map_options()) :: map() | no_return()
  def json_decode!(body, %{json_module: {json_module, json_apps}} = opts) do
    ensure_all_started!(json_apps)
    json_decode!(body, %{opts | json_module: json_module})
  end

  def json_decode!(body, opts) do
    opts.json_module.decode!(body)
  end

  # Since we are running this early in the boot process, applications may not be
  # started and should be passed in to the config to ensure they are started before
  # using them.
  defp ensure_all_started!(apps) do
    apps
    |> List.wrap()
    |> Enum.each(&({:ok, _} = Application.ensure_all_started(&1)))
  end

  # Get the HTTP module from the opts or provide a default (if the dependency exists).
  # Raises an error if none provided and optional dependencies aren't installed.
  defp http_module_from_opts(opts) do
    case Keyword.get(opts, :http_module) do
      nil ->
        if Code.ensure_loaded?(Mojito) do
          {DopplerConfigProvider.HTTPClient.MojitoClient, :mojito}
        else
          raise ArgumentError,
            message: "Must include :http_module, or add :mojito as a dependency"
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
            {Jason, :jason}

          Code.ensure_loaded?(Poison) ->
            {Poison, :poison}

          true ->
            raise ArgumentError,
              message: "Must include :json_module, or add :jason or :poison as a dependency"
        end

      json_module ->
        json_module
    end
  end

  defp merge_opts_to_map(app_config, opts) do
    config = Keyword.merge(app_config, opts)

    config
    |> Enum.into(%{})
    |> Map.put(:http_module, http_module_from_opts(config))
    |> Map.put(:json_module, json_module_from_opts(config))
  end
end
