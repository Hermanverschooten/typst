defprotocol Typst.Code do
  def encode(t)
end

defimpl Typst.Code, for: Map do
  def encode(map) when map_size(map) == 0 do
    "(:)"
  end

  def encode(map) do
    "(#{encode_kv(map)})"
  end

  def encode_kv(map) do
    Enum.map_join(map, ", ", fn
      {k, v} when is_binary(k) ->
        "#{String.Chars.BitString.to_string(k)}: #{Typst.Code.encode(v)}"

      {k, v} when is_atom(k) ->
        "#{Typst.Code.Atom.encode(k)}: #{Typst.Code.encode(v)}"
    end)
  end
end

defimpl Typst.Code, for: List do
  def encode(list) do
    if Keyword.keyword?(list) do
      "(#{Typst.Code.Map.encode_kv(list)})"
    else
      "(#{Enum.map_join(list, ", ", &Typst.Code.encode/1)})"
    end
  end
end

defimpl Typst.Code, for: Integer do
  def encode(int) do
    String.Chars.Integer.to_string(int)
  end
end

defimpl Typst.Code, for: Float do
  def encode(float) do
    String.Chars.Float.to_string(float)
  end
end

if Code.ensure_loaded?(Decimal) do
  defimpl Typst.Code, for: Decimal do
    def encode(decimal) do
      "decimal(\"#{Decimal.to_string(decimal)}\")"
    end
  end
end

defimpl Typst.Code, for: BitString do
  def encode(str) do
    if String.printable?(str) do
      encode_printable(str)
    else
      encode_bytes(str)
    end
  end

  defp encode_printable(str) do
    replacements = %{
      "\\" => "\\\\",
      "\"" => "\\\"",
      "\n" => "\\n",
      "\t" => "\\t",
      "\r" => "\\r"
    }

    escaped = String.replace(str, Map.keys(replacements), &Map.fetch!(replacements, &1))

    "\"#{escaped}\""
  end

  defp encode_bytes(bytes) do
    bytes =
      bytes
      |> :binary.bin_to_list()
      |> Enum.join(", ")

    "bytes(#{bytes})"
  end
end

defimpl Typst.Code, for: Atom do
  def encode(atom) do
    Atom.to_string(atom)
  end
end

defimpl Typst.Code, for: Tuple do
  def encode({:label, label}) when is_atom(label) do
    "<#{Atom.to_string(label)}>"
  end
end

defimpl Typst.Code, for: Date do
  def encode(date) do
    kv =
      Typst.Code.Map.encode_kv(
        year: date.year,
        month: date.month,
        day: date.day
      )

    "datetime(#{kv})"
  end
end

defimpl Typst.Code, for: Time do
  def encode(time) do
    kv =
      Typst.Code.Map.encode_kv(
        hour: time.hour,
        minute: time.minute,
        second: time.second
      )

    "datetime(#{kv})"
  end
end

defimpl Typst.Code, for: NaiveDateTime do
  def encode(naive) do
    kv =
      Typst.Code.Map.encode_kv(
        year: naive.year,
        month: naive.month,
        day: naive.day,
        hour: naive.hour,
        minute: naive.minute,
        second: naive.second
      )

    "datetime(#{kv})"
  end
end

defimpl Typst.Code, for: DateTime do
  def encode(datetime) do
    datetime
    |> DateTime.to_naive()
    |> Typst.Code.NaiveDateTime.encode()
  end
end

defimpl Typst.Code, for: Regex do
  def encode(regex) do
    "regex(`#{regex.source}`.text)"
  end
end
