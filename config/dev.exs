use Mix.Config

config :logger,
  level: :debug

config :rubixir, Rubixir.Worker,
  size: 1,
  max_overflow: 0
