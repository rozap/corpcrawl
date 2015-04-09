defmodule Corpcrawl.Mixfile do
  use Mix.Project

  def project do
    [app: :corpcrawl,
     version: "0.0.1",
     elixir: "~> 1.0",
     escript: escript,
     deps: deps]
  end

  defp escript do
    [main_module: Corpcrawl.Main]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :postgrex, :ecto]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:edgarex, git: "https://github.com/rozap/edgarex.git"},
      {:exquery, "~> 0.0.9"},
      {:ibrowse, github: "cmullaparthi/ibrowse", tag: "v4.1.1"},
      {:httpotion, "~> 2.0.0"},
      {:poison, "~> 1.3.1"},
      {:postgrex, "0.7.0"},
      {:ecto, "~> 0.8.1"} 
    ]
  end
end
