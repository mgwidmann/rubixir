defmodule RubixirTest do
  use Pavlov.Case, async: true
  import Pavlov.Syntax.Expect
  doctest Rubixir

  describe "#new" do

    context "default arguments" do

      it "basic ruby" do
        expect(Rubixir.run_sync("a = 1")) |> to_eq("1")
      end

      context "using the same worker" do
        let :worker, do: Rubixir.new
        before :each do
          on_exit fn ->
            Rubixir.close worker
          end
        end
        it "retains variables" do
          Rubixir.run_sync(worker, "a = 1")
          expect(Rubixir.run_sync(worker, "a += 1")) |> to_eq("2")

        end
      end
    end

  end

  describe "#run" do

    context "runs a command" do

      @tag :focus
      it "runs async" do
        ref = Rubixir.run("1")
        assert_receive {:ruby, ^ref, "1"}
      end

      it "runs sync" do
        expect(Rubixir.run_sync("1")) |> to_eq("1")
      end

    end

    context "runs multiple commands" do

      it "returns the last value" do
        expect(Rubixir.run_sync("1\n2")) |> to_eq("2")
      end

    end

    context "requires" do

      let :worker, do: Rubixir.new

      before :each do
        on_exit fn ->
          Rubixir.close worker
        end
      end

      it "after startup" do
        expect(Rubixir.run_sync(worker, "require('active_support') || require('active_support/core_ext') || true")) |> to_eq("true")
      end

      it "code is available" do
        expect(Rubixir.run_sync(worker, "require('active_support')\nrequire('active_support/core_ext')\n1.respond_to?(:present?)")) |> to_eq("true")
      end

      it "the Rubixir file" do
        expect(Rubixir.run_sync("$rubixir")) |> to_eq("true")
      end

    end

  end

  describe "puts" do
    import ExUnit.CaptureIO

    let :worker, do: Rubixir.new

    before :each do
      on_exit fn ->
        Rubixir.close worker
      end
    end

    @tag :focus
    it "forwards output to elixir to print" do
      # IO.puts "before changing io"
      # worker
      # |> Rubixir.Worker.change_io(:erlang.group_leader)

      # IO.puts "after changing io"

      # expect capture_io(fn ->
        Rubixir.run_sync worker, ~s(STDERR.puts "Hello Rubixir!")
      # end) == "Hello Rubixir!\n"
    end
  end

end
