defmodule Rubixir.MacrosTest do
  use Pavlov.Case, async: true
  import Pavlov.Syntax.Expect
  import Support.Helpers
  import Rubixir.Macros
  doctest Rubixir.Macros

  describe "#ruby" do

    let :block do
      quote do
        true
        1
        nil
      end
    end
    it "blocks" do
       result = to_ruby_string(block)
       expect_to_match result, """
       true
       1
       nil
       """
    end

    context "primitives" do
      let :truthy, do: quote(do: true)
      it "true" do
        result = to_ruby_string(truthy)
        expect(result) |> to_eq("true")
      end

      let :falsey, do: quote(do: false)
      it "false" do
        result = to_ruby_string(falsey)
        expect(result) |> to_eq("false")
      end

      let :nil_value, do: quote(do: nil)
      it "nil" do
        result = to_ruby_string(nil_value)
        expect(result) |> to_eq("nil")
      end

      let :integer, do: quote(do: 1)
      it "simple numbers" do
        result = to_ruby_string(integer)
        expect(result) |> to_eq("1")
      end

      let :float, do: quote(do: 1.0)
      it "floats" do
        result = to_ruby_string(float)
        expect(result) |> to_eq("1.0")
      end

      let :atom, do: quote(do: :symbol)
      it "atoms" do
        result = to_ruby_string(atom)
        expect(result) |> to_eq(":symbol")
      end

      let :string, do: quote(do: "string")
      it "strings" do
        result = to_ruby_string(string)
        expect(result) |> to_eq(~s("string"))
      end

      let :char_list, do: quote(do: 'string')
      it "char lists" do
        result = to_ruby_string(char_list)
        expect(result) |> to_eq(~s([115, 116, 114, 105, 110, 103]))
      end

      let :tuple, do: quote(do: {1,2})
      it "tuples" do
        result = to_ruby_string(tuple)
        expect(result) |> to_eq("[1, 2]")
      end

      let :three_or_more_tuple, do: quote(do: {1,2,3})
      it "tuples with three or more elements" do
        result = to_ruby_string(three_or_more_tuple)
        expect(result) |> to_eq("[1, 2, 3]")
      end

      let :map_of_strings, do: quote(do: %{"key" => "value"})
      it "maps w/ strings" do
        result = to_ruby_string(map_of_strings)
        expect(result) |> to_eq(~s({"key" => "value"}))
      end

      let :map_of_atoms, do: quote(do: %{key: :value})
      it "maps w/ atoms" do
        result = to_ruby_string(map_of_atoms)
        expect(result) |> to_eq(~s({:key => :value}))
      end

      let :keyword, do: quote(do: [key: :value])
      it "keyword list" do
         result = to_ruby_string(keyword)
         expect(result) |> to_eq(~s({:key => :value}))
      end

      let :property, do: quote(do: [{"key", :value}])
      it "property list" do
         result = to_ruby_string(property)
         expect(result) |> to_eq(~s({"key" => :value}))
      end

      let :binary, do: quote(do: <<123, 123>>)
      it "binary" do
        result = to_ruby_string(binary)
        expect(result) |> to_eq("[123, 123]")
      end

      let :binary_with_size, do: quote(do: <<350::size(12), 350::size(12)>>)
      it "binary with size" do
        result = to_ruby_string(binary_with_size)
        expect(result) |> to_eq("[350, 350]")
      end

      let :local_variable, do: quote(do: some_var)
      it "local variable" do
        result = to_ruby_string(local_variable)
        expect(result) |> to_eq("some_var")
      end
    end

    context "mathematical operators" do

      let :plus, do: quote(do: 1 + 1)
      it "adds" do
        result = to_ruby_string(plus)
        expect(result) |> to_eq("1 + 1")
      end

      let :subtract, do: quote(do: 1 - 1)
      it "subtract" do
        result = to_ruby_string(subtract)
        expect(result) |> to_eq("1 - 1")
      end

      let :multiply, do: quote(do: 1 * 1)
      it "multiply" do
        result = to_ruby_string(multiply)
        expect(result) |> to_eq("1 * 1")
      end

      let :divide, do: quote(do: 1 / 1)
      it "divide" do
        result = to_ruby_string(divide)
        expect(result) |> to_eq("1 / 1")
      end

      let :int_divide, do: quote(do: div(1, 1))
      it "integer divide" do
        result = to_ruby_string(int_divide)
        expect(result) |> to_eq("(1).to_i / (1).to_i")
      end

      let :modulus, do: quote(do: rem(1, 1))
      it "modulus" do
        result = to_ruby_string(modulus)
        expect(result) |> to_eq("1 % 1")
      end

      let :bang, do: quote(do: !true)
      it "bang" do
        result = to_ruby_string(bang)
        expect(result) |> to_eq("!true")
      end
    end

    context "conditionals" do

      let :if_statement, do: quote(do: if(true, do: :yes))
      it "if statement" do
        result = to_ruby_string(if_statement)
        expect_to_match result, """
        if true
          :yes
        end
        """
      end

      let :if_else_statement, do: quote(do: if(true, [do: :yes, else: :no]))
      it "if else statement" do
        result = to_ruby_string(if_else_statement)
        expect_to_match result, """
        if true
          :yes
        else
          :no
        end
        """
      end

      let :unless_statement, do: quote(do: unless(true, do: :yes))
      it "unless statement" do
        result = to_ruby_string(unless_statement)
        expect_to_match result, """
        unless true
          :yes
        end
        """
      end

      let :unless_else_statement, do: quote(do: unless(true, [do: :yes, else: :no]))
      it "unless else statement" do
        result = to_ruby_string(unless_else_statement)
        expect_to_match result, """
        unless true
          :yes
        else
          :no
        end
        """
      end

      let :single_cond do
        quote do
          cond do
            1 -> :yes
          end
        end
      end
      it "single cond statement" do
        result = to_ruby_string(single_cond)
        expect_to_match result, """
        if 1
          :yes
        end
        """
      end

      let :cond_statement do
        quote do
          cond do
            1 -> :yes
            "string" -> :no
            nil -> :no
          end
        end
      end
      it "cond statement" do
        result = to_ruby_string(cond_statement)
        expect_to_match result, """
        if 1
          :yes
        elsif "string"
          :no
        elsif nil
          :no
        end
        """
      end

      let :equals, do: quote(do: 1 == 1)
      it "equals" do
        result = to_ruby_string(equals)
        expect(result) |> to_eq("1 == 1")
      end

      let :equals_complex, do: quote(do: [%{key: :value}] == SomeModule.fun_call(:data))
      it "equals complex" do
        result = to_ruby_string(equals_complex)
        expect(result) |> to_eq("[{:key => :value}] == SomeModule.fun_call(:data)")
      end

      let :greater, do: quote(do: 1 > 1)
      it "greater" do
        result = to_ruby_string(greater)
        expect(result) |> to_eq("1 > 1")
      end

      let :greater_complex, do: quote(do: [%{key: :value}] > SomeModule.fun_call(:data))
      it "greater complex" do
        result = to_ruby_string(greater_complex)
        expect(result) |> to_eq("[{:key => :value}] > SomeModule.fun_call(:data)")
      end

      let :less_than, do: quote(do: 1 < 1)
      it "less than" do
        result = to_ruby_string(less_than)
        expect(result) |> to_eq("1 < 1")
      end

      let :less_than_complex, do: quote(do: [%{key: :value}] < SomeModule.fun_call(:data))
      it "less than complex" do
        result = to_ruby_string(less_than_complex)
        expect(result) |> to_eq("[{:key => :value}] < SomeModule.fun_call(:data)")
      end

      let :greater_or_equal, do: quote(do: 1 >= 1)
      it "greater or equal" do
        result = to_ruby_string(greater_or_equal)
        expect(result) |> to_eq("1 >= 1")
      end

      let :greater_or_equal_complex, do: quote(do: [%{key: :value}] >= SomeModule.fun_call(:data))
      it "greater or equal complex" do
        result = to_ruby_string(greater_or_equal_complex)
        expect(result) |> to_eq("[{:key => :value}] >= SomeModule.fun_call(:data)")
      end

      let :less_than_or_equal, do: quote(do: 1 <= 1)
      it "less than or equal" do
        result = to_ruby_string(less_than_or_equal)
        expect(result) |> to_eq("1 <= 1")
      end

      let :less_than_or_equal_complex, do: quote(do: [%{key: :value}] <= SomeModule.fun_call(:data))
      it "less than or equal complex" do
        result = to_ruby_string(less_than_or_equal_complex)
        expect(result) |> to_eq("[{:key => :value}] <= SomeModule.fun_call(:data)")
      end

      let :and_operator, do: quote(do: true && false)
      it "and" do
        result = to_ruby_string(and_operator)
        expect(result) |> to_eq("true && false")
      end

      let :single_and_operator, do: quote(do: true and false)
      it "single and" do
        result = to_ruby_string(single_and_operator)
        expect(result) |> to_eq("true & false")
      end

      let :or_operator, do: quote(do: true || false)
      it "or" do
        result = to_ruby_string(or_operator)
        expect(result) |> to_eq("true || false")
      end

      let :single_or_operator, do: quote(do: true or false)
      it "single or" do
        result = to_ruby_string(single_or_operator)
        expect(result) |> to_eq("true | false")
      end
    end

    context "module" do
      let :module, do: quote(do: SomeModule)
      it "reference" do
        result = to_ruby_string(module)
        expect(result) |> to_eq("SomeModule")
      end

      let :define_module do
        quote do
          defmodule RubyModule do
          end
        end
      end
      it "defines" do
        result = to_ruby_string(define_module)
        expect_to_match result, """
        module RubyModule
          extend self

        end
        """
      end

      let :define_namespaced do
        quote do
          defmodule Namespaced.RubyModule do
          end
        end
      end
      it "defines namespaced" do
        result = to_ruby_string(define_namespaced)
        expect_to_match result, """
        module Namespaced::RubyModule
          extend self

        end
        """
      end

      let :define_module_with_body do
        quote do
          defmodule RubyModule do
            puts "Hi!"
          end
        end
      end
      it "defines with body" do
        result = to_ruby_string(define_module_with_body)
        expect_to_match result, """
        module RubyModule
          extend self
          puts("Hi!")
        end
        """
      end

      let :define_nested do
        quote do
          defmodule Namespaced do
            defmodule Nested do
            end
          end
        end
      end
      it "defines nested" do
        result = to_ruby_string(define_nested)
        expect_to_match result, """
        module Namespaced
          extend self
          module Nested
            extend self

          end

        end
        """
      end

      let :def_method do
        quote do
          def foo(), do: nil
        end
      end
      it "defines a method" do
        result = to_ruby_string(def_method)
        expect_to_match result, """
        def foo()
          nil
        end
        """
      end

      let :def_method_with_args do
        quote do
          def foo(a, b, c), do: nil
        end
      end
      it "defines a method with args" do
        result = to_ruby_string(def_method_with_args)
        expect_to_match result, """
        def foo(a, b, c)
          nil
        end
        """
      end
    end

    context "methods" do

      let :class_method, do: quote(do: Object.new)
      it "class" do
         result = to_ruby_string(class_method)
         expect(result) |> to_eq("Object.new()")
      end

      let :class_method_with_simple_param, do: quote(do: Object.new(1))
      it "class with simple param" do
         result = to_ruby_string(class_method_with_simple_param)
         expect(result) |> to_eq("Object.new(1)")
      end

      let :class_method_with_module_param, do: quote(do: Class.new(Object))
      it "class with module param" do
         result = to_ruby_string(class_method_with_module_param)
         expect(result) |> to_eq("Class.new(Object)")
      end

      let :class_method_with_multiple_params, do: quote(do: Object.new(1, true, :symbol))
      it "class with multiple params" do
         result = to_ruby_string(class_method_with_multiple_params)
         expect(result) |> to_eq("Object.new(1, true, :symbol)")
      end

      let :class_method_with_method_call, do: quote(do: Object.new.to_s)
      it "class with method call" do
         result = to_ruby_string(class_method_with_method_call)
         expect(result) |> to_eq("Object.new().to_s()")
      end

      let :class_method_with_method_call_with_params, do: quote(do: Object.new(true).to_s(123))
      it "class with method call with params" do
         result = to_ruby_string(class_method_with_method_call_with_params)
         expect(result) |> to_eq("Object.new(true).to_s(123)")
      end

      let :local_function, do: quote(do: some_fun())
      it "local function" do
        result = to_ruby_string(local_function)
        expect(result) |> to_eq("some_fun()")
      end

      let :local_function_with_params, do: quote(do: some_fun(1, 2))
      it "local function with params" do
        result = to_ruby_string(local_function_with_params)
        expect(result) |> to_eq("some_fun(1, 2)")
      end

      let :local_function_complex_params, do: quote(do: some_fun([], key: :value))
      it "local function with complex params" do
        result = to_ruby_string(local_function_complex_params)
        expect(result) |> to_eq("some_fun([], {:key => :value})")
      end

      let :bracket_syntax, do: quote(do: something[:data])
      it "hash access" do
        result = to_ruby_string(bracket_syntax)
        expect(result) |> to_eq("something[:data]")
      end

    end

    context "assignment" do

      let :simple_assignment, do: quote(do: a = 5)
      it "simple" do
        result = to_ruby_string(simple_assignment)
        expect_to_match result, """
        _rubixir_ = 5
        a = _rubixir_ rescue :_rubixir_nil_
        raise Rubixir::MatchError.new(_rubixir_) if a == :_rubixir_nil_
        _rubixir_
        """
      end

      let :hard_assignment, do: quote(do: 1 = 2)
      it "hard" do
        result = to_ruby_string(hard_assignment)
        expect_to_match result, """
        _rubixir_ = 2
        raise Rubixir::MatchError.new(_rubixir_) unless (1 == _rubixir_ rescue false)
        _rubixir_
        """
      end

      let :list_assignment, do: quote(do: [a | b] = [1,2])
      it "list" do
        result = to_ruby_string(list_assignment)
        expect_to_match result, """
        _rubixir_ = [1, 2]
        a = _rubixir_[0] rescue :_rubixir_nil_
        raise Rubixir::MatchError.new(_rubixir_) if a == :_rubixir_nil_
        b = _rubixir_[1..-1] rescue :_rubixir_nil_
        raise Rubixir::MatchError.new(_rubixir_) if b == :_rubixir_nil_
        _rubixir_
        """
      end

      let :list_multi_assignment, do: quote(do: [a, b] = [1,2])
      it "list multi" do
        result = to_ruby_string(list_multi_assignment)
        expect_to_match result, """
        _rubixir_ = [1, 2]
        a = _rubixir_[0] rescue :_rubixir_nil_
        raise Rubixir::MatchError.new(_rubixir_) if a == :_rubixir_nil_
        b = _rubixir_[1] rescue :_rubixir_nil_
        raise Rubixir::MatchError.new(_rubixir_) if b == :_rubixir_nil_
        _rubixir_
        """
      end

      let :list_multi_splat_assignment, do: quote(do: [a, b | c] = [1,2,3])
      it "list multi splat" do
        result = to_ruby_string(list_multi_splat_assignment)
        expect_to_match result, """
        _rubixir_ = [1, 2, 3]
        a = _rubixir_[0] rescue :_rubixir_nil_
        raise Rubixir::MatchError.new(_rubixir_) if a == :_rubixir_nil_
        b = _rubixir_[1] rescue :_rubixir_nil_
        raise Rubixir::MatchError.new(_rubixir_) if b == :_rubixir_nil_
        c = _rubixir_[2..-1] rescue :_rubixir_nil_
        raise Rubixir::MatchError.new(_rubixir_) if c == :_rubixir_nil_
        _rubixir_
        """
      end

      let :keyword_assignment, do: quote(do: [{:key, value}, {dynamic, :hard}] = [key: :value, dynamic: :hard])
      it "keyword" do
        result = to_ruby_string(keyword_assignment)
        expect_to_match result, """
        _rubixir_ = {:key => :value, :dynamic => :hard}
        value = _rubixir_[:key] rescue :_rubixir_nil_
        raise Rubixir::MatchError.new(_rubixir_) if value == :_rubixir_nil_
        dynamic = _rubixir_.find{|k,v|v==:hard}[0] rescue :_rubixir_nil_
        raise Rubixir::MatchError.new(_rubixir_) if dynamic == :_rubixir_nil_
        raise Rubixir::MatchError.new(_rubixir_) unless (:key == _rubixir_.find{|k,v|v==value}[0] rescue false)
        raise Rubixir::MatchError.new(_rubixir_) unless (:hard == _rubixir_[dynamic] rescue false)
        _rubixir_
        """
      end

      let :hard_list_assignment, do: quote(do: [1] = [2])
      it "hard list" do
        result = to_ruby_string(hard_list_assignment)
        expect_to_match result, """
        _rubixir_ = [2]
        raise Rubixir::MatchError.new(_rubixir_) unless (1 == _rubixir_[0] rescue false)
        _rubixir_
        """
      end

      let :tuple_assignment, do: quote(do: {a, b} = {1, 2})
      it "tuple" do
        result = to_ruby_string(tuple_assignment)
        expect_to_match result, """
        _rubixir_ = [1, 2]
        a = _rubixir_[0] rescue :_rubixir_nil_
        raise Rubixir::MatchError.new(_rubixir_) if a == :_rubixir_nil_
        b = _rubixir_[1] rescue :_rubixir_nil_
        raise Rubixir::MatchError.new(_rubixir_) if b == :_rubixir_nil_
        _rubixir_
        """
      end

      let :tuple_multi_assignment, do: quote(do: {a, b, c} = {1, 2, 3})
      it "tuple multi" do
        result = to_ruby_string(tuple_multi_assignment)
        expect_to_match result, """
        _rubixir_ = [1, 2, 3]
        a = _rubixir_[0] rescue :_rubixir_nil_
        raise Rubixir::MatchError.new(_rubixir_) if a == :_rubixir_nil_
        b = _rubixir_[1] rescue :_rubixir_nil_
        raise Rubixir::MatchError.new(_rubixir_) if b == :_rubixir_nil_
        c = _rubixir_[2] rescue :_rubixir_nil_
        raise Rubixir::MatchError.new(_rubixir_) if c == :_rubixir_nil_
        _rubixir_
        """
      end

      let :map_assignment, do: quote(do: %{key: value} = %{key: :value})
      it "map" do
        result = to_ruby_string(map_assignment)
        expect_to_match result, """
        _rubixir_ = {:key => :value}
        value = _rubixir_[:key] rescue :_rubixir_nil_
        raise Rubixir::MatchError.new(_rubixir_) if value == :_rubixir_nil_
        raise Rubixir::MatchError.new(_rubixir_) unless (:key == _rubixir_.find{|k,v|v==value}[0] rescue false)
        _rubixir_
        """
      end
    end

  end

end
