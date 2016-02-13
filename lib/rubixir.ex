defmodule Rubixir do
  use Application

  defmacro __using__(_opts) do
    quote do
      import Rubixir.Macros
    end
  end

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      :poolboy.child_spec(Rubixir.Worker.pool_name, Rubixir.Worker.pool_config, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Rubixir.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defdelegate run(worker, statement), to: Rubixir.Worker
  defdelegate run_sync(worker, statement), to: Rubixir.Worker

  def run(statement) do
    :poolboy.transaction(Rubixir.Worker.pool_name, fn(worker)->
      run(worker, statement)
    end)
  end

  def run_sync(statement) do
    :poolboy.transaction(Rubixir.Worker.pool_name, fn(worker)->
      run_sync(worker, statement)
    end)
  end

  def new() do
    :poolboy.checkout(Rubixir.Worker.pool_name)
  end

  def close(worker) do
    :poolboy.checkin(Rubixir.Worker.pool_name, worker)
  end
end
