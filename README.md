# DopplerConfigProvider

[![Tests](https://github.com/sevenshores/doppler_config_provider/actions/workflows/tests.yml/badge.svg)](https://github.com/sevenshores/doppler_config_provider/actions/workflows/tests.yml)
 [![Hex.pm](https://img.shields.io/hexpm/v/doppler_config_provider)](https://github.com/sevenshores/doppler_config_provider/actions/workflows/tests.yml)
 [![Hex.pm](https://img.shields.io/hexpm/dt/doppler_config_provider)](https://hex.pm/packages/doppler_config_provider)
 [![Hex.pm](https://img.shields.io/hexpm/l/doppler_config_provider)](https://www.apache.org/licenses/LICENSE-2.0)

[Doppler](https://doppler.com) ConfigProvider for [Elixir](https://elixir-lang.org/) projects.

## Installation

The package can be installed by adding `:doppler_config_provider` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:doppler_config_provider, "~> 0.4.1"},
    # Mojito is optional, but it is the default if you don't specify `:http_module` in options.
    {:mojito, "~> 0.7.10"},
  ]
end
```

## Usage

 1. Generate a [service token](https://docs.doppler.com/docs/enclave-service-tokens).
 2. Add necessary config.
 3. Add the config provider to `release` config in `mix.exs`.

### Options

 * `:service_token` (required) - The Doppler service token.
 * `:http_module` (optional) - The HTTP client module. Defaults to `{Mojito, :mojito}`. Should implement `DopplerConfigProvider.HTTPClient` behaviour.
 * `:json_module` (optional) - The JSON decoding module. Defaults to `{Jason, :jason}` or `{Poison, :poison}`. Should implement `DopplerConfigProvider.JSONDecoder` behaviour.
 * `:mappings` (required) - A map specifying how to translate the Doppler config to application config.

The `:http_module` and `:json_module` options can take either a module (e.g. `MyApp.Foobar`) or a tuple with the module
and the apps that need to be started for the module to work properly (e.g. `{MyApp.Foobar, :mojito}` or `{MyApp.Foobar, [:tesla, :hackney]}`).

### Config example:

```elixir
config :doppler_config_provider,
  service_token: System.fetch_env!("DOPPLER_TOKEN"),
  mappings: %{
    "DATABASE_URL" => [:my_app, MyApp.Repo, :url],
    "SECRET_KEY_BASE" => [:my_app, MyAppWeb.Endpoint, :secret_key_base],
    "STRIPE_SECRET_KEY" => [:stripity_stripe, :api_key],
  }
```

### `mix.exs` example:

```elixir
releases: [
  my_app: [
    # ...
    config_providers: [
      {DopplerConfigProvider, http_module: {MyDopplerHTTPClient, [:tesla, :hackney]}}
    ]
  ]
],
```

Notes:

 * The options provided to the config provider in `releases` are merged with
the config provided in your config files. The options passed in `mix.exs` take precedence.
