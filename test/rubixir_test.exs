defmodule RubixirTest do
  use Pavlov.Case, async: true
  import Pavlov.Syntax.Expect
  doctest Rubixir

  describe "#new" do

    context "default arguments" do

      it "basic ruby" do
        expect(Rubixir.run_sync("a = 1")) |> to_eq("1")
      end

      it "retains variables" do
        worker = Rubixir.new
        Rubixir.run_sync(worker, "a = 1")
        expect(Rubixir.run_sync(worker, "a += 1")) |> to_eq("2")
      end
    end

  end

  describe "#run" do

    context "runs a command" do

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

      it "after startup" do
        expect(Rubixir.run_sync(Rubixir.new, "require('active_support') || require('active_support/core_ext') || true")) |> to_eq("true")
      end

      it "code is available" do
        expect(Rubixir.run_sync(Rubixir.new, "require('active_support')\nrequire('active_support/core_ext')\n1.respond_to?(:present?)")) |> to_eq("true")
      end

      it "the Rubixir file" do
        expect(Rubixir.run_sync("$rubixir")) |> to_eq("true")
      end

    end

  end

end
