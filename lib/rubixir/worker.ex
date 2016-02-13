defmodule Rubixir.Worker do
  use GenServer
  alias Porcelain.Process, as: Proc
  alias Rubixir.Worker.Job
  require Logger

  @rubixir_file Application.get_env(:rubixir, :rubixir_file)
  @ruby_loop """
    #{if @rubixir_file, do: "Module.new.module_eval(File.read(#{inspect Path.join(@rubixir_file, "Rubixir")}))", else: nil}
    STDOUT.sync = true
    context = binding

    while (cmd = gets) do
      puts eval(cmd, context).inspect
    end
  """

  @pool_config [
    name: {:local, __MODULE__},
    worker_module: __MODULE__,
    size: Application.get_env(:rubixir, __MODULE__)[:size] || 1,
    max_overflow: Application.get_env(:rubixir, __MODULE__)[:max_overflow] || 0
  ]

  def pool_name(), do: __MODULE__
  def pool_config(), do: @pool_config

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
    ref = make_ref()
    GenServer.cast(worker, {:run, statement, self, ref})
    ref
  end

  def run_sync(worker, statement) do
    run(worker, statement)
    |> await
  end

  def await(ref) do
    receive do
      {:ruby, ^ref, data} -> data
    end
  end

  def handle_cast({:run, statement, requested, ref}, {ruby, jobs}) do
    Logger.debug "Running:\n#{statement}"
    Proc.send_input(ruby, "#{statement}\n")
    {:noreply, {ruby, [ %Job{statement: statement, requested: requested, ref: ref, return: String.split(statement, "\n", trim: true) |> Enum.count} | jobs]}}
  end

  def handle_info({_port, :data, :out, data}, {ruby, jobs}) do
    jobs = handle_jobs(data, jobs)
    {:noreply, {ruby, jobs}}
  end

  def handle_info({_port, :result, %Porcelain.Result{} = result}, state) do
    Logger.error "Rubixir: #{inspect self} received exception and exited with status: #{result.status}"
    {:stop, :eof_stdin, state}
  end

  defp handle_jobs("\n", []), do: []
  defp handle_jobs(result, [job | jobs]) when is_binary(result) do
    result = String.split(result, "\n", trim: true)
    result_count = Enum.count(result)
    if job.return - result_count == 0 do
      send(job.requested, {:ruby, job.ref, result |> List.last})
      jobs
    else
      [%{job | return: job.return - result_count}]
    end
  end
  defp handle_jobs(result, jobs) do
    raise "Mismatch of results and jobs: \nresult: #{inspect result}\njobs: #{inspect jobs}"
  end

end
