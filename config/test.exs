use Mix.Config

config :logger,
  level: :info

config :rubixir, Rubixir.Worker,
  size: 4,
  max_overflow: 4

config :rubixir,
  rubixir_file: "test/support"
