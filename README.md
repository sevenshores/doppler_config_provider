# DopplerConfigProvider

[Doppler](https://doppler.com) ConfigProvider for [Elixir](https://elixir-lang.org/) projects.

## Installation

The package can be installed by adding `:doppler_config_provider` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:doppler_config_provider, "~> 0.1.0"},
    # Mojito is optional, but it is the default if you don't specify `:http_module` in options.
    {:mojito, "~> 0.7.10"},
  ]
end
```

The docs can be found at <https://hexdocs.pm/doppler_config_provider>.

## Usage

 1. Generate a [service token](https://docs.doppler.com/docs/enclave-service-tokens).
 2. Add necessary config.
 3. Add the config provider to `release` config in `mix.exs`.

### Options

 * `:service_token` (required) - The Doppler service token.
 * `:http_module` (optional) - The Doppler service token. Defaults to `{:mojito, Mojito}`.
 * `:json_module` (optional) - The Doppler service token. Defaults to `{:jason, Jason}` or `{:poison, Poison}`.
 * `:mappings` (required) - The Doppler service token.

Note: The options provided to the config provider in `releases` are merged with
the config provided in your config files.
### Config example:

```elixir
config :doppler_config_provider,
  service_token: System.fetch_env!("DOPPLER_TOKEN"),
  mappings: %{
    "DATABASE_URL" => {:my_app, MyApp.Repo, :url},
    "SECRET_KEY_BASE" => {:my_app, MyAppWeb.Endpoint, :secret_key_base},
    "STRIPE_SECRET_KEY" => {:stripity_stripe, :api_key},
  }
```

### `mix.exs` example:

```elixir
releases: [
  release_name: [
    include_executables_for: [:unix],
    applications: [
      runtime_tools: :permanent,
      app_name_here: :permanent
    ],
    config_providers: [
      {DopplerConfigProvider, http_module: MyFinchDopplerClient}
    ]
  ]
],
```
