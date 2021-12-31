defmodule DopplerConfigProvider.MixProject do
  use Mix.Project

  def project do
    [
      app: :doppler_config_provider,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs(),
      dialyzer: [plt_file: {:no_warn, "priv/plts/dialyzer.plt"}],
      source_url: "https://github.com/sevenshores/doppler_config_provider",
      homepage_url: "https://github.com/sevenshores/doppler_config_provider"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.3", optional: true},
      {:finch, "~> 0.10", optional: true},
      {:mojito, "~> 0.7.10", optional: true},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.26", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    Doppler config provider for Elixir projects.
    """
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/sevenshores/doppler_config_provider"},
      maintainers: ["Ryan Winchester"],
      source_url: "https://github.com/sevenshores/doppler_config_provider",
      homepage_url: "https://github.com/sevenshores/doppler_config_provider"
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end
end
