# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config
config :logger, :console,
	level: :info

config :corpcrawl, Corpcrawl.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "corpcrawl",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"
