defmodule Typst.Engine do
  @moduledoc """
  Custom EEx engine that automatically encodes Elixir values into Typst syntax.

  This engine extends the default `EEx.Engine` with Typst-aware encoding:

    * `<%= expr %>` — encodes the expression using `Typst.Code.encode/1` (code context)
    * `<%| expr %>` — encodes the expression using `Typst.Markup.encode/1` (markup context)
    * `<% expr %>` — executes the expression without output (same as default)

  All markers support `@variable` assign syntax like Phoenix LiveView.

  ## Usage

  Pass this engine to `EEx.eval_string/3`:

      EEx.eval_string(
        ~S|#text(font: <%= @font %>)[<%| @name %>]|,
        [assigns: %{font: "Roboto", name: "World"}],
        engine: Typst.Engine
      )
      # => ~S|#text(font: "Roboto")[World]|

  Or use the `~TYPST` sigil from `Typst` for compile-time templates.
  """

  @behaviour EEx.Engine

  @impl true
  defdelegate init(opts), to: EEx.Engine

  @impl true
  defdelegate handle_body(state), to: EEx.Engine

  @impl true
  defdelegate handle_begin(state), to: EEx.Engine

  @impl true
  defdelegate handle_end(state), to: EEx.Engine

  @impl true
  defdelegate handle_text(state, meta, text), to: EEx.Engine

  @impl true
  def handle_expr(state, "", expr) do
    expr = Macro.prewalk(expr, &EEx.Engine.handle_assign/1)
    EEx.Engine.handle_expr(state, "", expr)
  end

  def handle_expr(state, "=", expr) do
    expr = Macro.prewalk(expr, &EEx.Engine.handle_assign/1)
    %{binary: binary, dynamic: dynamic, vars_count: vars_count} = state
    var = Macro.var(:"arg#{vars_count}", __MODULE__)

    ast =
      quote do
        unquote(var) = Typst.Code.encode(unquote(expr))
      end

    segment =
      quote do
        unquote(var) :: binary
      end

    %{state | dynamic: [ast | dynamic], binary: [segment | binary], vars_count: vars_count + 1}
  end

  def handle_expr(state, "|", expr) do
    expr = Macro.prewalk(expr, &EEx.Engine.handle_assign/1)
    %{binary: binary, dynamic: dynamic, vars_count: vars_count} = state
    var = Macro.var(:"arg#{vars_count}", __MODULE__)

    ast =
      quote do
        unquote(var) = Typst.Markup.encode(unquote(expr))
      end

    segment =
      quote do
        unquote(var) :: binary
      end

    %{state | dynamic: [ast | dynamic], binary: [segment | binary], vars_count: vars_count + 1}
  end
end
