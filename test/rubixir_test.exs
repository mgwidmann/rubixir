defmodule RubixirTest do
  use Pavlov.Case, async: true
  import Pavlov.Syntax.Expect
  doctest Rubixir

  describe "#new" do

    context "default arguments" do
      let :worker, do: Rubixir.new

      it "basic ruby" do
        expect Rubixir.run_sync(worker, "a = 1") |> to_eq "1"
      end

      it "retains variables" do
        Rubixir.run_sync(worker, "a = 1")
        expect Rubixir.run_sync(worker, "a += 1") |> to_eq "2"
      end
    end

    context "with requires" do
      let :worker, do: Rubixir.new require: [:"active_support/core_ext"]

      it "loads the code" do
        expect Rubixir.run_sync(worker, "1.respond_to?(:present?)") |> to_eq "true"
      end
    end
  end

  describe "#run" do

    let :worker, do: Rubixir.new

    context "runs a command" do

      it "runs async" do
        w = worker # Need local variable for ^ pin below
        Rubixir.run(w, "1")
        assert_receive {:ruby, ^w, "1"}
      end

      it "runs sync" do
        expect Rubixir.run_sync(worker, "1") |> to_eq "1"
      end

    end

    context "requires" do

      it "after startup" do
        expect Rubixir.run_sync(worker, "require('active_support/core_ext')") |> to_eq "true"
      end

      it "code is available" do
        expect Rubixir.run_sync(worker, "require('active_support/core_ext') && 1.respond_to?(:present?)") |> to_eq "true"
      end

    end

  end

end
