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
        data = Erlang.term_to_binary(object) rescue object.inspect
        STDOUT.original_puts data
      end
    end

    module Kernel
      alias_method :original_puts, :puts
      def puts(s)
        Rubixir.transfer_data ":__rubixir__ \#{s.inspect}"
      end
      public :original_puts
    end

    while (cmd = gets) do
      Rubixir.transfer_data eval(cmd, context)
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
    script = "ruby -e '#{@ruby_loop}' -rerlang/etf #{Enum.join(requires, " ")}"
    ruby = Porcelain.spawn_shell(script, out: {:send, self}, in: :receive)
    {:ok, {ruby, [], :erlang.group_leader}}
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

  def handle_cast({:run, statement, requested, ref}, {ruby, jobs, gl}) do
    line_list = String.split(statement, "\n", trim: true)
    line_count = line_list |> Enum.count
    statement = "#{line_list |> Enum.join("\n")}\n"
    Logger.debug "Running:\n#{statement}"
    Proc.send_input(ruby, statement)
    {:noreply, {ruby, [ %Job{statement: statement, requested: requested, ref: ref, return: line_count} | jobs], gl}}
  end

  def handle_cast({:puts_device, group_leader}, {ruby, jobs, _gl}) do
    {:noreply, {ruby, jobs, group_leader}}
  end

  def handle_info({_port, :data, :out, data}, {ruby, jobs, gl}) do
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
             |> Enum.map(&binary/1)
             |> puts_ruby([], gl)
    result_count = Enum.count(result)
    if job.return - result_count <= 0 do
      binary = result |> List.last
      send(job.requested, {:ruby, job.ref, filter_binary(binary)})
      jobs
    else
      [%{job | return: job.return - result_count}]
    end
  end
  defp handle_jobs(result, jobs, _) do
    raise "Mismatch of results and jobs: \nresult: #{inspect result}\njobs: #{inspect jobs}"
  end

  defp puts_ruby([], acc, _), do: Enum.reverse(acc)
  defp puts_ruby([":__rubixir__ " <> string | rest], acc, gl) do
    puts = string
           |> String.splitter(~s("), trim: true)
           |> Enum.join
    IO.puts(gl, puts)

    puts_ruby(rest, acc, gl)
  end
  defp puts_ruby([i | rest], acc, gl) do
    puts_ruby(rest, [i|acc], gl)
  end

  defp binary(binary) do
    try do
      :erlang.binary_to_term(binary)
    rescue
      _ -> binary
    end
  end

  defp filter_binary({:bert, :dict, kv}), do: kv
  defp filter_binary({:bert, atom}) when is_atom(atom), do: atom
  defp filter_binary(binary), do: binary

end
