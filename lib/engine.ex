defmodule Typst.Engine do
  @behaviour EEx.Engine

  @impl EEx.Engine
  def init(opts) do
    EEx.Engine.init(opts)
  end

  @impl EEx.Engine
  def handle_body(state) do
    EEx.Engine.handle_body(state)
  end

  @impl EEx.Engine
  def handle_begin(state) do
    EEx.Engine.handle_begin(state)
  end

  @impl EEx.Engine
  def handle_end(state) do
    EEx.Engine.handle_end(state)
  end

  @impl EEx.Engine
  def handle_text(state, meta, text) do
    EEx.Engine.handle_text(state, meta, text)
  end

  @impl EEx.Engine
  def handle_expr(state, "=", ast) do
    %{binary: binary, dynamic: dynamic, vars_count: vars_count} = state
    var = Macro.var(:"arg#{vars_count}", __MODULE__)

    ast =
      quote do
        unquote(var) = Typst.Encode.to_string(unquote(ast))
      end

    segment =
      quote do
        unquote(var) :: binary
      end

    %{state | dynamic: [ast | dynamic], binary: [segment | binary], vars_count: vars_count + 1}
  end

  def handle_expr(state, marker, expr) do
    EEx.Engine.handle_expr(state, marker, expr)
  end
end
