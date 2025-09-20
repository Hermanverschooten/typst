defprotocol Typst.Encode do
  def to_string(t)
end

defimpl Typst.Encode, for: Map do
  def to_string(map) when map_size(map) == 0 do
    "(:)"
  end

  def to_string(map) do
    "(#{encode_kv(map)})"
  end

  def encode_kv(map) do
    Enum.map_join(map, ", ", fn
      {k, v} when is_binary(k) ->
        "#{String.Chars.BitString.to_string(k)}: #{Typst.Encode.to_string(v)}"

      {k, v} when is_atom(k) ->
        "#{Typst.Encode.Atom.to_string(k)}: #{Typst.Encode.to_string(v)}"
    end)
  end
end

defimpl Typst.Encode, for: List do
  def to_string(list) do
    if Keyword.keyword?(list) do
      "(#{Typst.Encode.Map.encode_kv(list)})"
    else
      "(#{Enum.map_join(list, ", ", &Typst.Encode.to_string/1)})"
    end
  end
end

defimpl Typst.Encode, for: Integer do
  def to_string(int) do
    String.Chars.Integer.to_string(int)
  end
end

defimpl Typst.Encode, for: Float do
  def to_string(float) do
    String.Chars.Float.to_string(float)
  end
end

if Code.ensure_loaded?(Decimal) do
  defimpl Typst.Encode, for: Decimal do
    def to_string(decimal) do
      "decimal(\"#{Decimal.to_string(decimal)}\")"
    end
  end
end

defimpl Typst.Encode, for: BitString do
  def to_string(str) do
    if String.printable?(str) do
      to_string_printable(str)
    else
      to_bytes(str)
    end
  end

  defp to_string_printable(str) do
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

  defp to_bytes(bytes) do
    bytes =
      bytes
      |> :binary.bin_to_list()
      |> Enum.join(", ")

    "bytes(#{bytes})"
  end
end

defimpl Typst.Encode, for: Atom do
  def to_string(atom) do
    Atom.to_string(atom)
  end
end

defimpl Typst.Encode, for: Tuple do
  def to_string({:label, label}) when is_atom(label) do
    "<#{Atom.to_string(label)}>"
  end
end

defimpl Typst.Encode, for: Date do
  def to_string(date) do
    kv =
      Typst.Encode.Map.encode_kv(
        year: date.year,
        month: date.month,
        day: date.day
      )

    "datetime(#{kv})"
  end
end

defimpl Typst.Encode, for: Time do
  def to_string(time) do
    kv =
      Typst.Encode.Map.encode_kv(
        hour: time.hour,
        minute: time.minute,
        second: time.second
      )

    "datetime(#{kv})"
  end
end

defimpl Typst.Encode, for: NaiveDateTime do
  def to_string(naive) do
    kv =
      Typst.Encode.Map.encode_kv(
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

defimpl Typst.Encode, for: DateTime do
  def to_string(datetime) do
    datetime
    |> DateTime.to_naive()
    |> Typst.Encode.NaiveDateTime.to_string()
  end
end

defimpl Typst.Encode, for: Regex do
  def to_string(regex) do
    "regex(`#{regex.source}`.text)"
  end
end
