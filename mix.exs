defmodule Wobserver2.Mixfile do
  use Mix.Project

  def project do
    [
      app: :wobserver,
      version: "0.1.9",
      elixir: "~> 1.4",
      description: "Web based metrics, monitoring, and observer.",
      package: package(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Testing
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: [ignore_warnings: "dialyzer.ignore-warnings"],
      # Docs
      name: "Wobserver",
      source_url: "https://github.com/shinyscorpion/wobserver",
      homepage_url: "https://github.com/shinyscorpion/wobserver",
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  def package do
    [
      name: :wobserver,
      maintainers: ["Ian Luites"],
      licenses: ["MIT"],
      files: [
        # Elixir
        "lib/wobserver",
        "lib/Wobserver2.ex",
        "mix.exs",
        "README*",
        "LICENSE*"
      ],
      links: %{
        "GitHub" => "https://github.com/shinyscorpion/wobserver"
      }
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      extra_applications: [
        :eex,
        :logger,
        :kernel,
        :stdlib,
        :ssl,
        :inets,
        :ranch,
        :cowboy
      ],
      mod: {Wobserver2.Application, []}
    ]
  end

  defp deps do
    [
      {:cowboy, "~> 2.4"},
      {:credo, "~> 0.10", only: [:dev, :test]},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.15", only: :dev},
      {:excoveralls, "~> 0.6", only: :test},
      {:inch_ex, "~> 0.5", only: [:dev, :test]},
      {:meck, "~> 0.8.4", only: :test},
      {:plug, "~> 1.6"},
      {:jason, "~> 1.1"},
      {:websocket_client, "~> 1.3"}
    ]
  end
end
