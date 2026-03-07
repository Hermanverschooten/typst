defprotocol Typst.Code do
  @moduledoc """
  Protocol for encoding Elixir values into Typst code syntax.

  This protocol is used by `Typst.Engine` for `<%= %>` expressions,
  converting Elixir values into their Typst code representation
  (used in function arguments, parameters, etc.).

  ## Examples

      iex> Typst.Code.encode(42)
      "42"

      iex> Typst.Code.encode(:center)
      "center"

      iex> Typst.Code.encode([1, 2, 3])
      "(1, 2, 3)"

  """

  @doc "Encodes a value into Typst code syntax."
  @spec encode(t) :: String.t()
  def encode(value)
end

defimpl Typst.Code, for: Integer do
  def encode(value), do: Integer.to_string(value)
end

defimpl Typst.Code, for: Float do
  def encode(value), do: Float.to_string(value)
end

defimpl Typst.Code, for: Atom do
  def encode(nil), do: "none"
  def encode(true), do: "true"
  def encode(false), do: "false"
  def encode(value), do: Atom.to_string(value)
end

defimpl Typst.Code, for: BitString do
  def encode(value) when is_binary(value) do
    escaped =
      value
      |> String.replace("\\", "\\\\")
      |> String.replace("\"", "\\\"")
      |> String.replace("\n", "\\n")
      |> String.replace("\t", "\\t")
      |> String.replace("\r", "\\r")

    "\"#{escaped}\""
  end
end

defimpl Typst.Code, for: List do
  def encode([{key, _} | _] = value) when is_atom(key) do
    inner =
      value
      |> Enum.map(fn {k, v} -> "#{k}: #{Typst.Code.encode(v)}" end)
      |> Enum.join(", ")

    "(#{inner})"
  end

  def encode(value) do
    inner =
      value
      |> Enum.map(&Typst.Code.encode/1)
      |> Enum.join(", ")

    "(#{inner})"
  end
end

defimpl Typst.Code, for: Map do
  def encode(value) when map_size(value) == 0, do: "(:)"

  def encode(value) do
    inner =
      value
      |> Enum.map(fn {k, v} -> "#{k}: #{Typst.Code.encode(v)}" end)
      |> Enum.join(", ")

    "(#{inner})"
  end
end

defimpl Typst.Code, for: Tuple do
  def encode({:label, value}), do: "<#{value}>"
end

defimpl Typst.Code, for: Date do
  def encode(value) do
    "datetime(year: #{value.year}, month: #{value.month}, day: #{value.day})"
  end
end

defimpl Typst.Code, for: Time do
  def encode(value) do
    "datetime(hour: #{value.hour}, minute: #{value.minute}, second: #{value.second})"
  end
end

defimpl Typst.Code, for: NaiveDateTime do
  def encode(value) do
    "datetime(year: #{value.year}, month: #{value.month}, day: #{value.day}, hour: #{value.hour}, minute: #{value.minute}, second: #{value.second})"
  end
end

defimpl Typst.Code, for: DateTime do
  def encode(value) do
    "datetime(year: #{value.year}, month: #{value.month}, day: #{value.day}, hour: #{value.hour}, minute: #{value.minute}, second: #{value.second})"
  end
end

defimpl Typst.Code, for: Regex do
  def encode(value) do
    "regex(\"#{Regex.source(value)}\")"
  end
end

if Code.ensure_loaded?(Decimal) do
  defimpl Typst.Code, for: Decimal do
    def encode(value) do
      "decimal(\"#{Decimal.to_string(value)}\")"
    end
  end
end
