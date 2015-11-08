defmodule Rubixer do
  use Application

  defmacro __using__(_opts) do
    quote do
      import Rubixer.Macros
    end
  end

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      worker(Rubixer.Worker, []),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :simple_one_for_one, name: Rubixer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defdelegate run(worker, statement), to: Rubixer.Worker
  defdelegate run_sync(worker, statement), to: Rubixer.Worker

  def new(opts \\ []) do
    {:ok, worker} = Supervisor.start_child Rubixer.Supervisor, [[require: opts[:require]]]
    worker
  end
end
