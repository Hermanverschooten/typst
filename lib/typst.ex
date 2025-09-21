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

  @doc """

  """
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

  @type pdf_opt :: {:extra_fonts, list(String.t())}

  @spec render_to_pdf(String.t(), list(pdf_opt)) :: {:ok, binary()} | {:error, String.t()}
  @doc """
  Converts a given piece of typst markup to a PDF binary.

  ## Examples

      iex> {:ok, pdf} = Typst.render_to_pdf("= test\\ncontent")
      iex> is_binary(pdf)
      true

  """
  def render_to_pdf(typst_markup, opts \\ []) do
    extra_fonts = Keyword.get(opts, :extra_fonts, []) ++ @embedded_fonts
    root_dir = Keyword.get(opts, :root_dir, ".")
    Typst.NIF.compile(typst_markup, root_dir, extra_fonts)
  end

  @spec render_to_pdf!(String.t(), list(formattable)) :: binary()
  @doc """
  Same as `render_to_pdf/2`, but raises if the rendering fails.
  """
  def render_to_pdf!(typst_markup, opts \\ []) do
    case render_to_pdf(typst_markup, opts) do
      {:ok, pdf} -> pdf
      {:error, reason} -> raise "could not build pdf: #{reason}"
    end
  end
end
