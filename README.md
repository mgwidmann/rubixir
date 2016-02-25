# Rubixir

Run ruby code from the Erlang VM by writing it in Elixir syntax.

## Installation

  1. Add rubixir to your list of dependencies in mix.exs:

    ```elixir
    def deps do
      [{:rubixir, "~> 0.0.1"}]
    end
    ```

  2. Ensure rubixir is started before your application:

    ```elixir
    def application do
      [applications: [:rubixir]]
    end
    ```

## Examples

Here is an example using a class method to create a new object from a literal and then call a method on the resulting object. Notice the syntax is in Elixir syntax, but the generated string is in Ruby syntax.

```elixir
iex> to_ruby_string(quote do
iex>   Hash.new(%{key: :value}).to_s
iex> end)
"Hash.new({:key => :value}).to_s()"
```

So the only difference here is the way a map/hash is represented in both languages. Thats only because of the overlap in syntax. What went on was a complete compilation of Elixir AST to Ruby code, the Elixir statement was not simply transformed using `Macro.to_string/1`.

Pattern matching is also supported!

```elixir
iex> to_ruby_string(quote do
iex>  [1, a, 3] = [1, 2, 3]
iex> end) |> IO.puts
_rubixir_ = [1, 2, 3]
a = _rubixir_[1] rescue :_rubixir_nil_
raise Rubixir::MatchError.new(_rubixir_) if a == :_rubixir_nil_
raise Rubixir::MatchError.new(_rubixir_) unless (1 == _rubixir_[0] rescue false)
raise Rubixir::MatchError.new(_rubixir_) unless (3 == _rubixir_[2] rescue false)
_rubixir_
```

Patterns with hard values will raise exceptions on the ruby side, which gets propagated back to your Elixir code.

You can then talk directly to a ruby process like so:

```elixir
iex> worker = Rubixir.new
iex> ruby worker do
iex>   puts "Hello Rubixir world!"
iex> end
Hello Rubixir world!
```

And get data back from it (in development):

```elixir
iex> user_posts = ruby do
iex>   User.find(unquote(user_id)).posts
iex> end
```
