defmodule Rubixir.Worker do
  use GenServer
  alias Porcelain.Process, as: Proc
  alias Rubixir.Worker.Job
  require Logger

  @ruby_loop ~S"""
    STDOUT.sync = true
    context = binding

    while (cmd = gets) do
      puts eval(cmd, context).inspect
    end
  """

  def start_link(opts) do
    GenServer.start_link __MODULE__, opts
  end

  def init(opts) do
    requires = Enum.map(opts[:require] || [], &("-r#{to_string(&1)}"))
    script = "ruby -e '#{@ruby_loop}' #{Enum.join(requires, " ")}"
    ruby = Porcelain.spawn_shell(script, out: {:send, self}, in: :receive)
    {:ok, {ruby, []}}
  end

  def run(worker, statement) do
    GenServer.cast(worker, {:run, statement, self})
    worker
  end

  def run_sync(worker, statement) do
    run(worker, statement)
    |> receive_result
  end

  def receive_result(worker) do
    receive do
      {:ruby, ^worker, data} -> data
    end
  end

  def handle_cast({:run, statement, requested}, {ruby, jobs}) do
    Logger.debug "Running:\n#{statement}"
    Proc.send_input(ruby, "#{statement}\n")
    {:noreply, {ruby, [ %Job{statement: statement, requested: requested} | jobs]}}
  end

  def handle_info({_port, :data, :out, data}, {ruby, jobs}) do
    jobs = handle_jobs(data, jobs)
    {:noreply, {ruby, jobs}}
  end

  def handle_info({_port, :result, %Porcelain.Result{} = result}, state) do
    Logger.error "Rubixir: #{inspect self} received exception and exited with status: #{result.status}"
    {:stop, :eof_stdin, state}
  end

  defp handle_jobs(data, jobs) when is_binary(data) do
    handle_jobs(String.split(data, "\n", trim: true), jobs)
  end
  defp handle_jobs([result | results], [job | jobs]) do
    send(job.requested, {:ruby, self, result})
  end
  defp handle_jobs(results, jobs) do
    raise "Mismatch of results and jobs: \nresults: #{inspect results}\njobs: #{inspect jobs}"
  end

end
