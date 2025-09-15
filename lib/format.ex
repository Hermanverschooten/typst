defmodule Typst.Format do
  @moduledoc """
  Contains helper functions for converting elixir datatypes into
  the format that Typst expects
  """

  @type column_data :: String.t() | integer

  @spec bold(String.Chars.t()) :: String.t()
  def bold(el), do: ["*", el, "*"] |> IO.iodata_to_binary()

  @spec content(String.Chars.t()) :: String.t()
  def content(nil), do: "[]"
  def content(el), do: ["[", to_string(el), "]"] |> IO.iodata_to_binary()
end
