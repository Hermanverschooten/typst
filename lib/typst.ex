defmodule Typst do
  @moduledoc """
  This module provides the core functions for interacting with
  the `typst` markup language compiler.

  Note that when using the formatting directives, they are exactly the same as
  `EEx`, so all of its constructs are supported.

  See [Typst's documentation](https://typst.app/docs) for a quickstart.
  """

  @embedded_fonts [Path.join(:code.priv_dir(:typst), "fonts")]

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

  @spec render_to_pdf(String.t(), list(formattable()), list(typst_opt())) ::
          {:ok, binary()} | {:error, String.t()}
  @doc """
  Converts a given piece of typst markup to a PDF binary.

  ## Options

  This function takes the following options:

    * `:extra_fonts` - a list of directories to seatch for fonts

    * `:root_dir` - the root directory for typst, where all filepaths are resolved from. defaults to the current directory

    * `:assets` - a list of `{"name", binary()}` or enumerable to store blobs in the typst virtual file system

    * `:trim` - when `true`, trims blank lines left by EEx tags. Defaults to `false`.

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
    extra_fonts = Keyword.get(opts, :extra_fonts, []) ++ @embedded_fonts
    root_dir = Keyword.get(opts, :root_dir, ".")

    assets =
      Keyword.get(opts, :assets, [])
      |> Enum.map(fn {key, val} -> {to_string(key), val} end)

    trim = Keyword.get(opts, :trim, false)
    markup = render_to_string(typst_markup, bindings, trim: trim)

    Typst.NIF.compile_pdf(markup, root_dir, extra_fonts, assets)
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

    * `:extra_fonts` - a list of directories to seatch for fonts

    * `:root_dir` - the root directory for typst, where all filepaths are resolved from. defaults to the current directory

    * `:pixels_per_pt` - specifies how many pixels represent one pt unit

    * `:assets` - a list of `{"name", binary()}` or enumerable to store blobs in the typst virtual file system

    * `:trim` - when `true`, trims blank lines left by EEx tags. Defaults to `false`.

  ## Examples

      iex> {:ok, pngs} = Typst.render_to_png("= test\\n<%= name %>", name: "John")
      iex> is_list(pngs)
      true

  """
  def render_to_png(typst_markup, bindings \\ [], opts \\ []) do
    extra_fonts = Keyword.get(opts, :extra_fonts, []) ++ @embedded_fonts
    root_dir = Keyword.get(opts, :root_dir, ".")
    pixels_per_pt = Keyword.get(opts, :pixels_per_pt, 1.0)

    assets =
      Keyword.get(opts, :assets, [])
      |> Enum.map(fn {key, val} -> {to_string(key), val} end)

    trim = Keyword.get(opts, :trim, false)
    markup = render_to_string(typst_markup, bindings, trim: trim)

    Typst.NIF.compile_png(markup, root_dir, extra_fonts, pixels_per_pt, assets)
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
end
