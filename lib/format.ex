defmodule Typst.Format do
  @moduledoc """
  Contains helper functions for converting Elixir datatypes into
  the format that Typst expects.

  These functions are useful when building Typst markup with EEx templates.

  ## Examples

      iex> Typst.render_to_string("Name: <%= name %>", name: Typst.Format.bold("Alice"))
      "Name: *Alice*"

      iex> Typst.render_to_string("columns: <%= cols %>", cols: Typst.Format.array(["1fr", "2fr"]))
      "columns: (1fr, 2fr)"
  """

  @doc """
  Escapes special Typst markup characters in the given string by prefixing them with a backslash.

  This is useful when inserting user-provided text that should be rendered literally,
  without triggering Typst's markup syntax.

  The following characters are escaped: `\\`, `*`, `_`, `` ` ``, `$`, `#`, `@`, `<`, `>`, `~`, `=`, `-`, `+`, `/`, `[`, `]`

  Note: the `\\\\` in the examples below is Elixir's string representation of a single backslash.

  ## Examples

      iex> Typst.Format.escape("hello *world*")
      "hello \\\\*world\\\\*"

      iex> Typst.Format.escape("email@example.com")
      "email\\\\@example.com"

      iex> Typst.Format.escape("price is $10")
      "price is \\\\$10"

  """
  @spec escape(String.t()) :: String.t()
  def escape(text) when is_binary(text) do
    String.replace(text, ~w(\\ * _ ` $ # @ < > ~ = - + / [ ]), &"\\#{&1}")
  end

  @doc """
  Wraps the given element in Typst bold markers (`*...*`).

  ## Examples

      iex> Typst.Format.bold("hello")
      "*hello*"

      iex> Typst.Format.bold(42)
      "*42*"

  """
  @spec bold(String.Chars.t()) :: String.t()
  def bold(el), do: ["*", to_string(el), "*"] |> IO.iodata_to_binary()

  @doc """
  Wraps the given element in Typst content brackets (`[...]`).

  Returns `[]` for `nil` values.

  ## Examples

      iex> Typst.Format.content("hello")
      "[hello]"

      iex> Typst.Format.content(nil)
      "[]"

  """
  @spec content(String.Chars.t()) :: String.t()
  def content(nil), do: "[]"
  def content(el), do: ["[", to_string(el), "]"] |> IO.iodata_to_binary()

  @doc """
  Converts a list into a Typst array `(...)`.

  ## Examples

      iex> Typst.Format.array(["1fr", "2fr", "1fr"])
      "(1fr, 2fr, 1fr)"

      iex> Typst.Format.array(["red", "blue"])
      "(red, blue)"

  """
  @spec array(list()) :: String.t()
  def array(list) when is_list(list),
    do: (["("] ++ Enum.intersperse(list, ", ") ++ [")"]) |> IO.iodata_to_binary()

  @doc false
  def if_set(nil, _), do: []
  def if_set(_, content_fn) when is_function(content_fn), do: content_fn.()
  def if_set(_, content), do: content

  @doc false
  def recurse(content) when is_list(content) do
    content
    |> List.flatten()
    |> Enum.map(&process/1)
    |> Enum.intersperse(", ")
  end

  def recurse(content), do: process(content)

  defp process(element) when is_struct(element), do: to_string(element)
  defp process(element), do: content(element)

  @doc false
  def join_parts(parts) do
    parts
    |> Enum.reject(&(&1 == []))
    |> Enum.intersperse(", ")
  end
end
