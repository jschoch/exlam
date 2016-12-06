defmodule Exlam.Mixfile do
  use Mix.Project

  def project do
    [app: app(),
     version: version(),
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps()]
  end

  defp version, do: "0.0.2"

  defp app, do: :exlam

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  defp aliases do
    [
      build: [ &build_releases/1],
    ]
  end

  defp build_releases(_) do
    Mix.Tasks.Compile.run([])
    Mix.Tasks.Archive.Build.run([])
    Mix.Tasks.Archive.Build.run(["--output=#{app}.ez"])
    File.rename("#{app}.ez", "./archives/#{app}.ez")
    File.rename("#{app}-#{version}.ez", "./archives/#{app}-#{version}.ez")
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:distillery, "~> 0.10"},
      {:http_server, git: "https://github.com/jschoch/elixir_http_server", only: :test},
      {:ex_aws, "~> 1.0.0-beta0"},
      {:poison, "~> 2.0"},
      {:hackney, "~> 1.6"}
    ]
  end
end
