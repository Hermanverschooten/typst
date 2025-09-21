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
    ast = traverse(ast)
    %{binary: binary, dynamic: dynamic, vars_count: vars_count} = state
    var = Macro.var(:"arg#{vars_count}", __MODULE__)

    ast =
      quote do
        unquote(var) = Typst.Code.encode(unquote(ast))
      end

    segment =
      quote do
        unquote(var) :: binary
      end

    %{state | dynamic: [ast | dynamic], binary: [segment | binary], vars_count: vars_count + 1}
  end

  def handle_expr(state, "|", ast) do
    ast = traverse(ast)
    %{binary: binary, dynamic: dynamic, vars_count: vars_count} = state
    var = Macro.var(:"arg#{vars_count}", __MODULE__)

    ast =
      quote do
        unquote(var) = Typst.Markup.encode(unquote(ast))
      end

    segment =
      quote do
        unquote(var) :: binary
      end

    %{state | dynamic: [ast | dynamic], binary: [segment | binary], vars_count: vars_count + 1}
  end

  def handle_expr(state, marker, expr) do
    expr = traverse(expr)
    EEx.Engine.handle_expr(state, marker, expr)
  end

  # Assigns Traversal
  # There is `EEx.Engine.handle_assign/1`, but it doesn't raise, but only warn.
  #
  defp traverse(expr) do
    Macro.prewalk(expr, &handle_assign/1)
  end

  defp handle_assign({:@, meta, [{name, _, atom}]}) when is_atom(name) and is_atom(atom) do
    quote line: meta[:line] || 0 do
      Typst.Engine.fetch_assign!(var!(assigns), unquote(name))
    end
  end

  defp handle_assign(arg), do: arg

  @doc false
  def fetch_assign!(assigns, key) do
    case Access.fetch(assigns, key) do
      {:ok, val} ->
        val

      :error ->
        raise ArgumentError, """
        assign @#{key} not available in template.

        Please make sure all proper assigns have been set. If this
        is a child template, ensure assigns are given explicitly by
        the parent template as they are not automatically forwarded.

        Available assigns: #{inspect(Enum.map(assigns, &elem(&1, 0)))}
        """
    end
  end
end
