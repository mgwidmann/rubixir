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

    module Rubixir
      extend self
      def transfer_data(object)
        STDERR.puts "Got object: \#{object.inspect}"
        STDOUT.puts object.inspect
        STDERR.puts "Done with output"
      end
    end

    while (cmd = gets) do
      Rubixir.transfer_data eval(cmd, context)
      STDERR.puts "data transfered"
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
    {:ok, {ruby, [], :erlang.group_leader()}}
  end

  def run(worker, statement) do
    ref = make_ref()
    GenServer.cast(worker, {:run, statement, self, ref})
    IO.puts "Sent data to worker"
    ref
  end

  def run_sync(worker, statement) do
    run(worker, statement)
    |> IO.inspect
    |> await
  end

  def await(ref) do
    IO.puts "waiting on ref"
    receive do
      {:ruby, ^ref, data} -> data
    end
  end

  def handle_cast({:run, statement, requested, ref}, {ruby, jobs, gl}) do
    Logger.debug "Running:\n#{statement}"
    statement = "#{String.strip(statement)}\n"
    Proc.send_input(ruby, statement)
    {:noreply, {ruby, [ %Job{statement: statement, requested: requested, ref: ref, return: String.split(statement, "\n", trim: true) |> Enum.count} | jobs]}, gl}
  end

  def handle_cast({:puts_device, group_leader}, {ruby, jobs, _gl}) do
    Logger.debug "Rubixir: IO device changed to #{inspect group_leader}"
    {:noreply, {ruby, jobs, group_leader}}
  end

  def handle_info({_port, :data, :out, data}, {ruby, jobs, gl}) do
    IO.puts "Got data #{inspect data}"
    jobs = handle_jobs(data, jobs, gl)
    {:noreply, {ruby, jobs, gl}}
  end

  def handle_info({_port, :result, %Porcelain.Result{} = result}, state) do
    Logger.error "Rubixir: #{inspect self} received exception and exited with status: #{result.status}"
    {:stop, :eof_stdin, state}
  end

  def change_io(worker, group_leader) do
    GenServer.cast(worker, {:puts_device, group_leader})
  end

  defp handle_jobs("\n", [], _), do: []
  defp handle_jobs(result, [job | jobs], gl) when is_binary(result) do
    result = String.split(result, "\n", trim: true)
             |> puts_ruby([], gl)
    result_count = Enum.count(result)
    if job.return - result_count <= 0 do
      IO.puts "sending result #{inspect result} to #{job.requested}"
      send(job.requested, {:ruby, job.ref, result |> List.last})
      jobs
    else
      IO.puts "updating job to be #{job.return - result_count}"
      [%{job | return: job.return - result_count}]
    end
  end
  defp handle_jobs(result, jobs) do
    raise "Mismatch of results and jobs: \nresult: #{inspect result}\njobs: #{inspect jobs}"
  end

  defp puts_ruby([], acc, _), do: Enum.reverse(acc)
  defp puts_ruby([~s(:__rubixir__ ) <> string | rest], acc, gl) do
    string
    |> String.splitter(~s("), trim: true)
    |> Enum.join
    |> IO.puts

    IO.inspect :erlang.group_leader
    puts_ruby(rest, ["nil" | acc], gl)
  end
  defp puts_ruby([i | rest], acc, gl) do
    IO.puts "puts_ruby"
    puts_ruby(rest, [i|acc], gl)
  end

end
