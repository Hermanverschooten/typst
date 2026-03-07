defprotocol Typst.Code do
  @moduledoc """
  Protocol for encoding Elixir values into Typst code syntax.

  This protocol is used by `Typst.Engine` for `<%= %>` expressions,
  converting Elixir values into their Typst code representation
  (used in function arguments, parameters, etc.).

  ## Encoding reference

  | Type | Elixir | Typst |
  |------|--------|-------|
  | Integer | `42` | `42` |
  | Float | `3.14` | `3.14` |
  | Atom | `:center` | `center` |
  | Boolean | `true` / `false` | `true` / `false` |
  | Nil | `nil` | `none` |
  | Printable string | `"hello"` | `"hello"` (with `\\`, `"`, `\\n`, `\\t`, `\\r` escaped) |
  | Non-printable binary | `<<0, 1, 2>>` | `bytes(0, 1, 2)` |
  | List | `[1, 2, 3]` | `(1, 2, 3)` |
  | Keyword | `[a: 1, b: 2]` | `(a: 1, b: 2)` |
  | Map | `%{a: 1}` | `(a: 1)` |
  | Empty map | `%{}` | `(:)` |
  | Label | `{:label, :intro}` | `<intro>` |
  | Date | `~D[2024-01-15]` | `datetime(year: 2024, month: 1, day: 15)` |
  | Time | `~T[13:45:00]` | `datetime(hour: 13, minute: 45, second: 0)` |
  | NaiveDateTime | `~N[2024-01-15 13:45:00]` | `datetime(year: 2024, month: 1, ...)` |
  | DateTime | same as NaiveDateTime | |
  | Regex | `~r/foo/` | `` regex(`foo`.text) `` |
  | Decimal | `Decimal.new("1.5")` | `decimal("1.5")` (requires `:decimal` dependency) |

  ## Custom implementations

  Both `Typst.Code` and `Typst.Markup` are protocols, so you can implement
  them for your own types. For example, if you need locale-aware number
  formatting in markup context, format the value before passing it in:

      <%| MyApp.Cldr.Number.to_string!(@price) %>

  Or implement the protocol for a wrapper struct:

      defimpl Typst.Code, for: MyApp.Currency do
        def encode(%{amount: amount, currency: cur}) do
          "\\"" <> cur <> " " <> to_string(amount) <> "\\""
        end
      end

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
    if String.printable?(value) do
      encode_printable(value)
    else
      encode_bytes(value)
    end
  end

  defp encode_printable(value) do
    escaped =
      value
      |> String.replace("\\", "\\\\")
      |> String.replace("\"", "\\\"")
      |> String.replace("\n", "\\n")
      |> String.replace("\t", "\\t")
      |> String.replace("\r", "\\r")

    "\"#{escaped}\""
  end

  defp encode_bytes(bytes) do
    inner =
      bytes
      |> :binary.bin_to_list()
      |> Enum.join(", ")

    "bytes(#{inner})"
  end
end

defimpl Typst.Code, for: List do
  def encode(list) do
    if Keyword.keyword?(list) and list != [] do
      "(#{Typst.Code.Map.encode_kv(list)})"
    else
      "(#{Enum.map_join(list, ", ", &Typst.Code.encode/1)})"
    end
  end
end

defimpl Typst.Code, for: Map do
  def encode(map) when map_size(map) == 0, do: "(:)"

  def encode(map) do
    "(#{encode_kv(map)})"
  end

  def encode_kv(enumerable) do
    Enum.map_join(enumerable, ", ", fn
      {k, v} when is_binary(k) ->
        "#{k}: #{Typst.Code.encode(v)}"

      {k, v} when is_atom(k) ->
        "#{Atom.to_string(k)}: #{Typst.Code.encode(v)}"
    end)
  end
end

defimpl Typst.Code, for: Tuple do
  def encode({:label, value}), do: "<#{value}>"
end

defimpl Typst.Code, for: Date do
  def encode(value) do
    kv = Typst.Code.Map.encode_kv(year: value.year, month: value.month, day: value.day)
    "datetime(#{kv})"
  end
end

defimpl Typst.Code, for: Time do
  def encode(value) do
    kv = Typst.Code.Map.encode_kv(hour: value.hour, minute: value.minute, second: value.second)
    "datetime(#{kv})"
  end
end

defimpl Typst.Code, for: NaiveDateTime do
  def encode(value) do
    kv =
      Typst.Code.Map.encode_kv(
        year: value.year,
        month: value.month,
        day: value.day,
        hour: value.hour,
        minute: value.minute,
        second: value.second
      )

    "datetime(#{kv})"
  end
end

defimpl Typst.Code, for: DateTime do
  @doc """
  Encodes a `DateTime` as a Typst `datetime`. Timezone information is dropped
  since Typst does not support timezones — the time values are used as-is
  (already adjusted to the timezone).
  """
  def encode(value) do
    value
    |> DateTime.to_naive()
    |> Typst.Code.NaiveDateTime.encode()
  end
end

defimpl Typst.Code, for: Regex do
  def encode(value) do
    "regex(`#{Regex.source(value)}`.text)"
  end
end

if Code.ensure_loaded?(Decimal) do
  defimpl Typst.Code, for: Decimal do
    def encode(value) do
      "decimal(\"#{Decimal.to_string(value)}\")"
    end
  end
end
