defmodule Oriio.MixProject do
  use Mix.Project

  def project do
    [
      app: :oriio,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: dialyzer()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Oriio.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix_pubsub, "~> 2.0"},
      {:ecto, "~> 3.6"},
      {:postgrex, ">= 0.0.0"},
      {:jason, "~> 1.2"},
      {:swoosh, "~> 1.3"},
      {:horde, "~> 0.8.6"},
      {:libcluster, "~> 3.3.1"},
      {:delta_crdt, "~> 0.6.4"},
      {:briefly, "~> 0.3"},
      {:timex, "~> 3.0"},
      {:statix, "~>1.4"},
      {:statsd_logger, "~> 1.1", only: [:dev, :test]},
      {:vix, "~> 0.7.0"},
      {:kino, "~> 0.3.0"},
      {:telemetry_metrics_statsd, "~> 0.3.0"},
      {:ex_aws, "~> 2.1"},
      {:ex_aws_s3, "~> 2.0"},
      {:sweet_xml, "~> 0.7.1"},
      {:plug_crypto, "~> 1.0"},
      {:local_cluster, "~> 1.2", only: [:test]}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get"],
      test: ["test --no-start"]
    ]
  end

  defp dialyzer do
    [
      ignore_warnings: "../../.dialyzer_ignore.exs",
      plt_add_apps: [:mix, :ex_unit],
      plt_file: {:no_warn, "../../ops/plts/dialyzer.plt"}
    ]
  end
end
