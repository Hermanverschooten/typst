defmodule Typst do
  @moduledoc """
  This module provides the core functions for interacting with
  the `typst` markup language compiler.

  ## Two ways to compile Typst

  There are two families of functions depending on whether your Typst markup
  is a **plain string** or an **EEx template**:

  ### Plain strings — `to_pdf/2`, `to_png/2`, `to_svg/2`

  Use these when your Typst markup is already a complete string with no
  EEx directives to process. This is the case when:

    * You used the `~TYPST` sigil (which compiles the template at compile-time
      but evaluates assigns at runtime — so it works with dynamic data)
    * You read a `.typ` file from disk
    * You built the markup string yourself with interpolation or concatenation

      assigns = %{name: "World"}
      ~TYPST|= Hello <%| @name %>| |> Typst.to_pdf()

      File.read!("report.typ") |> Typst.to_pdf()

  ### EEx templates — `render_to_pdf/3`, `render_to_png/3`, `render_to_svg/3`

  Use these when the **template itself** is not known at compile-time — for
  example, a template stored in a database or loaded from a user-provided file
  that contains EEx directives (`<%= %>`) needing evaluation with bindings:

      template = File.read!("report.typ.eex")
      Typst.render_to_pdf(template, name: "World")

      Typst.render_to_pdf("= Hello <%= name %>", name: "World")

  > #### Avoid double-processing {: .warning}
  >
  > Do **not** pass `~TYPST` sigil output to `render_to_*` functions.
  > The sigil already processes EEx at compile-time, so `render_to_*` would
  > run EEx again on the result. Use `to_*` functions instead.

  ## Typst-aware engine

  For automatic encoding of Elixir values into Typst syntax, use `Typst.Engine`
  or the `~TYPST` sigil. The engine provides two markers:

    * `<%= expr %>` — encodes via `Typst.Code` (code context: atoms, strings, lists, dates, etc.)
    * `<%| expr %>` — encodes via `Typst.Markup` (markup context: content text)

  Both support `@variable` assigns syntax. See `Typst.Engine`, `Typst.Code`,
  and `Typst.Markup` for details.

  See [Typst's documentation](https://typst.app/docs) for a quickstart.
  """

  @embedded_fonts [Path.join(:code.priv_dir(:typst), "fonts")]

  @doc ~S'''
  Sigil for compile-time Typst templates using `Typst.Engine`.

  Uses `<%= %>` for code context (`Typst.Code`) and `<%| %>` for
  markup context (`Typst.Markup`). Supports `@variable` assigns syntax.

  The template is compiled at compile-time, so it must be a string literal.
  An `assigns` variable (map or keyword list) must be in scope.

  ## Inline usage

      import Typst, only: :sigils

      assigns = %{name: "World", font: "Roboto"}
      result = ~TYPST|#text(font: <%= @font %>)[<%| @name %>]|

  ## Using in a module

  Import the sigil and build a function that takes assigns:

      defmodule MyApp.Invoice do
        import Typst, only: :sigils

        def render(assigns) do
          ~TYPST"""
          #set text(font: <%= @font %>)

          = <%| @title %>

          #table(
            columns: <%= @columns %>,
            <%= for item <- @items do %>
              [<%| item.name %>], [<%| item.quantity %>],
            <% end %>
          )
          """
        end
      end

      MyApp.Invoice.render(%{
        font: "Roboto",
        title: "Invoice #123",
        columns: 2,
        items: [%{name: "Widget", quantity: "10"}]
      })

  ## Passing to compilation functions

  The sigil produces a plain string with EEx already evaluated, so pass
  it to `to_pdf/2`, `to_png/2`, or `to_svg/2` (not `render_to_*`, which
  would run EEx a second time):

      defmodule MyApp.Report do
        import Typst, only: :sigils

        def to_pdf(assigns) do
          ~TYPST"""
          #set align(<%= @align %>)
          = <%| @title %>
          """
          |> Typst.to_pdf()
        end
      end

  '''
  defmacro sigil_TYPST({:<<>>, meta, [expr]}, []) do
    if not Macro.Env.has_var?(__CALLER__, {:assigns, nil}) do
      raise "~TYPST requires a variable named \"assigns\" to exist and be set to a map"
    end

    options = [
      engine: Typst.Engine,
      file: __CALLER__.file,
      line: __CALLER__.line + 1,
      caller: __CALLER__,
      indentation: meta[:indentation] || 0,
      source: expr
    ]

    EEx.compile_string(expr, options)
  end

  @type compile_opt ::
          {:extra_fonts, list(String.t())}
          | {:root_dir, String.t()}
          | {:pixels_per_pt, number()}
          | {:assets, Keyword.t() | map() | list({String.t(), binary()})}
          | {:cache_fonts, boolean()}

  @doc """
  Compiles a Typst markup string directly to a PDF binary.

  Unlike `render_to_pdf/3`, this function does **not** process EEx templates.
  Use it when your markup is already a complete string — for example, output
  from the `~TYPST` sigil, a file read from disk, or a string from a database.

  ## Options

    * `:extra_fonts` - a list of directories to search for fonts

    * `:root_dir` - the root directory for typst, where all filepaths are
      resolved from. Defaults to the current directory.

    * `:assets` - a list of `{"name", binary()}` or enumerable to store blobs
      in the typst virtual file system

    * `:cache_fonts` - when `true`, caches scanned fonts across calls.
      Defaults to `true`.

  ## Examples

  With the `~TYPST` sigil:

      import Typst, only: :sigils

      assigns = %{name: "World"}
      ~TYPST|= Hello <%| @name %>| |> Typst.to_pdf()

  With a plain string:

      iex> {:ok, pdf} = Typst.to_pdf("= Hello World")
      iex> is_binary(pdf)
      true

  With a file from disk:

      File.read!("report.typ") |> Typst.to_pdf()

  """
  @spec to_pdf(String.t(), list(compile_opt())) :: {:ok, binary()} | {:error, String.t()}
  def to_pdf(typst_markup, opts \\ []) do
    {extra_fonts, root_dir, _pixels_per_pt, assets, cache_fonts} = extract_compile_opts(opts)
    Typst.NIF.compile_pdf(typst_markup, root_dir, extra_fonts, assets, cache_fonts)
  end

  @doc """
  Same as `to_pdf/2`, but raises if the compilation fails.
  """
  @spec to_pdf!(String.t(), list(compile_opt())) :: binary()
  def to_pdf!(typst_markup, opts \\ []) do
    case to_pdf(typst_markup, opts) do
      {:ok, pdf} -> pdf
      {:error, reason} -> raise "could not build pdf: #{reason}"
    end
  end

  @doc """
  Compiles a Typst markup string directly to a list of PNG binaries, one per page.

  Unlike `render_to_png/3`, this function does **not** process EEx templates.
  Use it when your markup is already a complete string — for example, output
  from the `~TYPST` sigil, a file read from disk, or a string from a database.

  ## Options

    * `:extra_fonts` - a list of directories to search for fonts

    * `:root_dir` - the root directory for typst, where all filepaths are
      resolved from. Defaults to the current directory.

    * `:pixels_per_pt` - specifies how many pixels represent one pt unit.
      Defaults to `1.0`.

    * `:assets` - a list of `{"name", binary()}` or enumerable to store blobs
      in the typst virtual file system

    * `:cache_fonts` - when `true`, caches scanned fonts across calls.
      Defaults to `true`.

  ## Examples

      iex> {:ok, pngs} = Typst.to_png("= Hello World")
      iex> is_list(pngs)
      true

  """
  @spec to_png(String.t(), list(compile_opt())) :: {:ok, list(binary())} | {:error, String.t()}
  def to_png(typst_markup, opts \\ []) do
    {extra_fonts, root_dir, pixels_per_pt, assets, cache_fonts} = extract_compile_opts(opts)
    Typst.NIF.compile_png(typst_markup, root_dir, extra_fonts, pixels_per_pt, assets, cache_fonts)
  end

  @doc """
  Same as `to_png/2`, but raises if the compilation fails.
  """
  @spec to_png!(String.t(), list(compile_opt())) :: list(binary())
  def to_png!(typst_markup, opts \\ []) do
    case to_png(typst_markup, opts) do
      {:ok, pngs} -> pngs
      {:error, reason} -> raise "could not build png: #{reason}"
    end
  end

  @doc """
  Compiles a Typst markup string directly to a list of SVG strings, one per page.

  Unlike `render_to_svg/3`, this function does **not** process EEx templates.
  Use it when your markup is already a complete string — for example, output
  from the `~TYPST` sigil, a file read from disk, or a string from a database.

  ## Options

    * `:extra_fonts` - a list of directories to search for fonts

    * `:root_dir` - the root directory for typst, where all filepaths are
      resolved from. Defaults to the current directory.

    * `:assets` - a list of `{"name", binary()}` or enumerable to store blobs
      in the typst virtual file system

    * `:cache_fonts` - when `true`, caches scanned fonts across calls.
      Defaults to `true`.

  ## Examples

      iex> {:ok, svgs} = Typst.to_svg("= Hello World")
      iex> is_list(svgs)
      true

  """
  @spec to_svg(String.t(), list(compile_opt())) :: {:ok, list(String.t())} | {:error, String.t()}
  def to_svg(typst_markup, opts \\ []) do
    {extra_fonts, root_dir, _pixels_per_pt, assets, cache_fonts} = extract_compile_opts(opts)
    Typst.NIF.compile_svg(typst_markup, root_dir, extra_fonts, assets, cache_fonts)
  end

  @doc """
  Same as `to_svg/2`, but raises if the compilation fails.
  """
  @spec to_svg!(String.t(), list(compile_opt())) :: list(String.t())
  def to_svg!(typst_markup, opts \\ []) do
    case to_svg(typst_markup, opts) do
      {:ok, svgs} -> svgs
      {:error, reason} -> raise "could not build svg: #{reason}"
    end
  end

  @type formattable :: {atom, any}

  @spec render_to_string(String.t(), list(formattable), list({:trim, boolean()})) :: String.t()

  @doc """
  Formats the given markup template with the given bindings, mostly
  useful for inspecting and debugging.

  ## Options

    * `:trim` - when `true`, trims blank lines left by EEx tags. Defaults to `false`.

  ## Examples

      iex> Typst.render_to_string("= Hey <%= name %>!", name: "Jude")
      "= Hey Jude!"

  """

  def render_to_string(typst_markup, bindings \\ [], opts \\ []) do
    trim = Keyword.get(opts, :trim, false)
    EEx.eval_string(typst_markup, bindings, trim: trim)
  end

  @type typst_opt ::
          {:extra_fonts, list(String.t())}
          | {:root_dir, String.t()}
          | {:pixels_per_pt, number()}
          | {:assets, Keyword.t() | map() | list({String.t(), binary()})}
          | {:trim, boolean()}
          | {:cache_fonts, boolean()}

  @spec render_to_pdf(String.t(), list(formattable()), list(typst_opt())) ::
          {:ok, binary()} | {:error, String.t()}
  @doc """
  Converts a given piece of typst markup to a PDF binary.

  ## Options

  This function takes the following options:

    * `:extra_fonts` - a list of directories to search for fonts

    * `:root_dir` - the root directory for typst, where all filepaths are resolved from. defaults to the current directory

    * `:assets` - a list of `{"name", binary()}` or enumerable to store blobs in the typst virtual file system

    * `:trim` - when `true`, trims blank lines left by EEx tags. Defaults to `false`.

    * `:cache_fonts` - when `true`, caches scanned fonts across calls. Defaults to `true`.

  ## Examples

      iex> {:ok, pdf} = Typst.render_to_pdf("= test\\n<%= name %>", name: "John")
      iex> is_binary(pdf)
      true

      iex> svg = ~S|<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="m19.5 8.25-7.5 7.5-7.5-7.5" /></svg>|
      iex> {:ok, pdf} = Typst.render_to_pdf(~S|#image(read("logo", encoding: none), width: 6cm)|, [], assets: [logo: svg])
      iex> is_binary(pdf)
      true

  """
  def render_to_pdf(typst_markup, bindings \\ [], opts \\ []) do
    {extra_fonts, root_dir, _pixels_per_pt, assets, cache_fonts} = extract_compile_opts(opts)
    trim = Keyword.get(opts, :trim, false)
    markup = render_to_string(typst_markup, bindings, trim: trim)
    Typst.NIF.compile_pdf(markup, root_dir, extra_fonts, assets, cache_fonts)
  end

  @spec render_to_pdf!(String.t(), list(formattable()), list(typst_opt())) :: binary()
  @doc """
  Same as `render_to_pdf/3`, but raises if the rendering fails.
  """
  def render_to_pdf!(typst_markup, bindings \\ [], opts \\ []) do
    case render_to_pdf(typst_markup, bindings, opts) do
      {:ok, pdf} -> pdf
      {:error, reason} -> raise "could not build pdf: #{reason}"
    end
  end

  @spec render_to_png(String.t(), list(formattable()), list(typst_opt())) ::
          {:ok, list(binary())} | {:error, String.t()}
  @doc """
  Converts a given piece of typst markup to a PNG binary, one per each page.
  #
  ## Options

  This function takes the following options:

    * `:extra_fonts` - a list of directories to search for fonts

    * `:root_dir` - the root directory for typst, where all filepaths are resolved from. defaults to the current directory

    * `:pixels_per_pt` - specifies how many pixels represent one pt unit

    * `:assets` - a list of `{"name", binary()}` or enumerable to store blobs in the typst virtual file system

    * `:trim` - when `true`, trims blank lines left by EEx tags. Defaults to `false`.

    * `:cache_fonts` - when `true`, caches scanned fonts across calls. Defaults to `true`.

  ## Examples

      iex> {:ok, pngs} = Typst.render_to_png("= test\\n<%= name %>", name: "John")
      iex> is_list(pngs)
      true

  """
  def render_to_png(typst_markup, bindings \\ [], opts \\ []) do
    {extra_fonts, root_dir, pixels_per_pt, assets, cache_fonts} = extract_compile_opts(opts)
    trim = Keyword.get(opts, :trim, false)
    markup = render_to_string(typst_markup, bindings, trim: trim)
    Typst.NIF.compile_png(markup, root_dir, extra_fonts, pixels_per_pt, assets, cache_fonts)
  end

  @spec render_to_png!(String.t(), list(formattable()), list(typst_opt())) :: list(binary())
  @doc """
  Same as `render_to_png/3`, but raises if the rendering fails.
  """
  def render_to_png!(typst_markup, bindings \\ [], opts \\ []) do
    case render_to_png(typst_markup, bindings, opts) do
      {:ok, png} -> png
      {:error, reason} -> raise "could not build png: #{reason}"
    end
  end

  @spec render_to_svg(String.t(), list(formattable()), list(typst_opt())) ::
          {:ok, list(String.t())} | {:error, String.t()}
  @doc """
  Converts a given piece of typst markup to SVG strings, one per each page.

  ## Options

  This function takes the following options:

    * `:extra_fonts` - a list of directories to search for fonts

    * `:root_dir` - the root directory for typst, where all filepaths are resolved from. defaults to the current directory

    * `:assets` - a list of `{"name", binary()}` or enumerable to store blobs in the typst virtual file system

    * `:trim` - when `true`, trims blank lines left by EEx tags. Defaults to `false`.

    * `:cache_fonts` - when `true`, caches scanned fonts across calls. Defaults to `true`.

  ## Examples

      iex> {:ok, svgs} = Typst.render_to_svg("= test\\n<%= name %>", name: "John")
      iex> is_list(svgs)
      true

  """
  def render_to_svg(typst_markup, bindings \\ [], opts \\ []) do
    {extra_fonts, root_dir, _pixels_per_pt, assets, cache_fonts} = extract_compile_opts(opts)
    trim = Keyword.get(opts, :trim, false)
    markup = render_to_string(typst_markup, bindings, trim: trim)
    Typst.NIF.compile_svg(markup, root_dir, extra_fonts, assets, cache_fonts)
  end

  @spec render_to_svg!(String.t(), list(formattable()), list(typst_opt())) :: list(String.t())
  @doc """
  Same as `render_to_svg/3`, but raises if the rendering fails.
  """
  def render_to_svg!(typst_markup, bindings \\ [], opts \\ []) do
    case render_to_svg(typst_markup, bindings, opts) do
      {:ok, svgs} -> svgs
      {:error, reason} -> raise "could not build svg: #{reason}"
    end
  end

  defp extract_compile_opts(opts) do
    extra_fonts = Keyword.get(opts, :extra_fonts, []) ++ @embedded_fonts
    root_dir = Keyword.get(opts, :root_dir, ".")
    pixels_per_pt = Keyword.get(opts, :pixels_per_pt, 1.0)
    cache_fonts = Keyword.get(opts, :cache_fonts, true)

    assets =
      Keyword.get(opts, :assets, [])
      |> Enum.map(fn {key, val} -> {to_string(key), val} end)

    {extra_fonts, root_dir, pixels_per_pt, assets, cache_fonts}
  end
end
