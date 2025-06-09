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

  @spec render_to_string(String.t(), list(formattable)) :: String.t()
  @doc """
  Formats the given markup template with the given bindings, mostly
  useful for inspecting and debugging.

  ## Examples

      iex> Typst.render_to_string("= Hey <%= name %>!", name: "Jude")
      "= Hey Jude!"

  """
  def render_to_string(typst_markup, bindings \\ []) do
    EEx.eval_string(typst_markup, bindings)
  end

  @type pdf_opt :: {:extra_fonts, list(String.t())}

  @spec render_to_pdf(String.t(), list(formattable), list(pdf_opt)) ::
          {:ok, binary()} | {:error, String.t()}
  @doc """
  Converts a given piece of typst markup to a PDF binary.

  ## Examples

      iex> {:ok, pdf} = Typst.render_to_pdf("= test\\n<%= name %>", name: "John")
      iex> is_binary(pdf)
      true

  """
  def render_to_pdf(typst_markup, bindings \\ [], opts \\ []) do
    extra_fonts = Keyword.get(opts, :extra_fonts, []) ++ @embedded_fonts
    root_dir = Keyword.get(opts, :root_dir, ".")

    markup =
      render_to_string(typst_markup, bindings)

    Typst.NIF.compile(markup, root_dir, extra_fonts)
  end

  @spec render_to_pdf!(String.t(), list(formattable)) :: binary()
  @doc """
  Same as `render_to_pdf/3`, but raises if the rendering fails.
  """
  def render_to_pdf!(typst_markup, bindings \\ [], opts \\ []) do
    case render_to_pdf(typst_markup, bindings, opts) do
      {:ok, pdf} -> pdf
      {:error, reason} -> raise "could not build pdf: #{reason}"
    end
  end
end
