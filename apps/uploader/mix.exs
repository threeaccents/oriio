defmodule Uploader.MixProject do
  use Mix.Project

  def project do
    [
      app: :uploader,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Uploader.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:oriio, in_umbrella: true},
      {:bst, in_umbrella: true},
      {:banzai, in_umbrella: true},
      {:briefly, "~> 0.3"},
      {:ex_mime, in_umbrella: true},
      {:local_cluster, "~> 1.2", only: [:test]},
      {:benchee, "~> 1.0", only: :dev}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      # {:sibling_app_in_umbrella, in_umbrella: true}
    ]
  end
end