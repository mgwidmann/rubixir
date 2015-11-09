defmodule Rubixir.MacrosTest do
  use Pavlov.Case, async: true
  import Pavlov.Syntax.Expect
  import Rubixir.Macros
  doctest Rubixir.Macros

  describe "#ruby" do

    context "primitives" do
      let :truthy, do: quote(do: true)
      it "true" do
        result = to_ruby_string(truthy)
        expect result |> to_eq "true"
      end

      let :falsey, do: quote(do: false)
      it "false" do
        result = to_ruby_string(falsey)
        expect result |> to_eq "false"
      end

      let :nil_value, do: quote(do: nil)
      it "nil" do
        result = to_ruby_string(nil_value)
        expect result |> to_eq "nil"
      end

      let :integer, do: quote(do: 1)
      it "simple numbers" do
        result = to_ruby_string(integer)
        expect result |> to_eq "1"
      end

      let :float, do: quote(do: 1.0)
      it "floats" do
        result = to_ruby_string(float)
        expect result |> to_eq "1.0"
      end

      let :atom, do: quote(do: :symbol)
      it "atoms" do
        result = to_ruby_string(atom)
        expect result |> to_eq(":symbol")
      end

      let :string, do: quote(do: "string")
      it "strings" do
        result = to_ruby_string(string)
        expect result |> to_eq ~s("string")
      end

      let :char_list, do: quote(do: 'string')
      it "char lists" do
        result = to_ruby_string(char_list)
        expect result |> to_eq ~s([115, 116, 114, 105, 110, 103])
      end

      let :tuple, do: quote(do: {1,2})
      it "tuples" do
        result = to_ruby_string(tuple)
        expect result |> to_eq "[1, 2]"
      end

      let :three_or_more_tuple, do: quote(do: {1,2,3})
      it "tuples with three or more elements" do
        result = to_ruby_string(three_or_more_tuple)
        expect result |> to_eq "[1, 2, 3]"
      end

      let :map_of_strings, do: quote(do: %{"key" => "value"})
      it "maps w/ strings" do
        result = to_ruby_string(map_of_strings)
        expect result |> to_eq ~s({"key" => "value"})
      end

      let :map_of_atoms, do: quote(do: %{key: :value})
      it "maps w/ atoms" do
        result = to_ruby_string(map_of_atoms)
        expect result |> to_eq ~s({:key => :value})
      end

      let :keyword, do: quote(do: [key: :value])
      it "keyword list" do
         result = to_ruby_string(keyword)
         expect result |> to_eq ~s({:key => :value})
      end

      let :property, do: quote(do: [{"key", :value}])
      it "property list" do
         result = to_ruby_string(property)
         expect result |> to_eq ~s({"key" => :value})
      end
    end

    context "conditionals" do

      let :if_statement, do: quote(do: if(true, do: :yes))
      it "if statement" do
        result = to_ruby_string(if_statement)
        expect result |> to_eq """
        if true
          :yes
        end
        """
      end

      let :if_else_statement, do: quote(do: if(true, [do: :yes, else: :no]))
      it "if else statement" do
        result = to_ruby_string(if_else_statement)
        expect result |> to_eq """
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
        expect result |> to_eq """
        unless true
          :yes
        end
        """
      end

      let :unless_else_statement, do: quote(do: unless(true, [do: :yes, else: :no]))
      it "unless else statement" do
        result = to_ruby_string(unless_else_statement)
        expect result |> to_eq """
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
        expect result |> to_eq """
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
        expect result |> to_eq """
        if 1
          :yes
        elsif "string"
          :no
        elsif nil
          :no
        end
        """
      end

    end

    context "module" do
      let :module, do: quote(do: SomeModule)
      it "..." do
        result = to_ruby_string(module)
        expect result |> to_eq("SomeModule")
      end
    end

    context "methods" do

      let :class_method, do: quote(do: Object.new)
      it "class" do
         result = to_ruby_string(class_method)
         expect result |> to_eq "Object.new()"
      end

      let :class_method_with_simple_param, do: quote(do: Object.new(1))
      it "class with simple param" do
         result = to_ruby_string(class_method_with_simple_param)
         expect result |> to_eq "Object.new(1)"
      end

      let :class_method_with_module_param, do: quote(do: Class.new(Object))
      it "class with module param" do
         result = to_ruby_string(class_method_with_module_param)
         expect result |> to_eq "Class.new(Object)"
      end

      let :class_method_with_multiple_params, do: quote(do: Object.new(1, true, :symbol))
      it "class with multiple params" do
         result = to_ruby_string(class_method_with_multiple_params)
         expect result |> to_eq "Object.new(1, true, :symbol)"
      end

      let :class_method_with_method_call, do: quote(do: Object.new.to_s)
      it "class with method call" do
         result = to_ruby_string(class_method_with_method_call)
         expect result |> to_eq "Object.new().to_s()"
      end

      let :class_method_with_method_call_with_params, do: quote(do: Object.new(true).to_s(123))
      it "class with method call with params" do
         result = to_ruby_string(class_method_with_method_call_with_params)
         expect result |> to_eq "Object.new(true).to_s(123)"
      end

    end

    context "assignment" do

      let :simple_assignment, do: quote(do: a = 5)
      it "simple" do
        result = to_ruby_string(simple_assignment)
        expect result |> to_eq """
        _rubixir_ = 5
        a = _rubixir_
        _rubixir_
        """
      end

      let :hard_assignment, do: quote(do: 1 = 2)
      it "hard" do
        result = to_ruby_string(hard_assignment)
        expect result |> to_eq """
        _rubixir_ = 2
        raise Rubixir::MatchError.new(_rubixir_) unless 1 == _rubixir_
        _rubixir_
        """
      end

      let :list_assignment, do: quote(do: [a | b] = [1,2])
      it "list" do
        result = to_ruby_string(list_assignment)
        expect result |> to_eq """
        _rubixir_ = [1, 2]
        a = _rubixir_[0]
        b = _rubixir_[1..-1]
        _rubixir_
        """
      end

      let :list_multi_assignment, do: quote(do: [a, b] = [1,2])
      it "list multi" do
        result = to_ruby_string(list_multi_assignment)
        expect result |> to_eq """
        _rubixir_ = [1, 2]
        a = _rubixir_[0]
        b = _rubixir_[1]
        _rubixir_
        """
      end

      let :list_multi_splat_assignment, do: quote(do: [a, b | c] = [1,2,3])
      it "list multi splat" do
        result = to_ruby_string(list_multi_splat_assignment)
        expect result |> to_eq """
        _rubixir_ = [1, 2, 3]
        a = _rubixir_[0]
        b = _rubixir_[1]
        c = _rubixir_[2..-1]
        _rubixir_
        """
      end

      let :hard_list_assignment, do: quote(do: [1] = [2])
      it "hard list" do
        result = to_ruby_string(hard_list_assignment)
        expect result |> to_eq """
        _rubixir_ = [2]
        raise Rubixir::MatchError.new(_rubixir_) unless 1 == _rubixir_[0]
        _rubixir_
        """
      end

      let :tuple_assignment, do: quote(do: {a, b} = {1, 2})
      it "tuple" do
        result = to_ruby_string(tuple_assignment)
        expect result |> to_eq """
        _rubixir_ = [1, 2]
        a = _rubixir_[0]
        b = _rubixir_[1]
        _rubixir_
        """
      end

      let :tuple_multi_assignment, do: quote(do: {a, b, c} = {1, 2, 3})
      it "tuple multi" do
        result = to_ruby_string(tuple_multi_assignment)
        expect result |> to_eq """
        _rubixir_ = [1, 2, 3]
        a = _rubixir_[0]
        b = _rubixir_[1]
        c = _rubixir_[2]
        _rubixir_
        """
      end

      # let :map_assignment, do: quote(do: %{key: value} = %{key: :value})
      # it "map" do
      #   result = to_ruby_string(map_assignment)
      #   expect result |> to_eq """
      #   _rubixir_hash_ = %{key: :value}
      #   raise Rubixir::MatchError.new(_rubixir_hash_) unless _rubixir_hash_.has_key?(:key)
      #   value = _rubixir_hash_[:key]
      #   """
      # end
    end

  end

end
