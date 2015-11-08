defmodule RubixerTest do
  use Pavlov.Case, async: true
  import Pavlov.Syntax.Expect
  doctest Rubixer

  describe "#new" do

    context "default arguments" do
      let :worker, do: Rubixer.new

      it "basic ruby" do
        expect Rubixer.run_sync(worker, "a = 1") |> to_eq "1"
      end

      it "retains variables" do
        Rubixer.run_sync(worker, "a = 1")
        expect Rubixer.run_sync(worker, "a += 1") |> to_eq "2"
      end
    end

    context "with requires" do
      let :worker, do: Rubixer.new require: [:"active_support/core_ext"]

      it "loads the code" do
        expect Rubixer.run_sync(worker, "1.respond_to?(:present?)") |> to_eq "true"
      end
    end
  end

  describe "#run" do

    let :worker, do: Rubixer.new

    context "runs a command" do

      it "runs async" do
        w = worker # Need local variable for ^ pin below
        Rubixer.run(w, "1")
        assert_receive {:ruby, ^w, "1"}
      end

      it "runs sync" do
        expect Rubixer.run_sync(worker, "1") |> to_eq "1"
      end

    end

    context "requires" do

      it "after startup" do
        expect Rubixer.run_sync(worker, "require('active_support/core_ext')") |> to_eq "true"
      end

      it "code is available" do
        expect Rubixer.run_sync(worker, "require('active_support/core_ext') && 1.respond_to?(:present?)") |> to_eq "true"
      end

    end

  end

end
