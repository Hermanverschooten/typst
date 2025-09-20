defprotocol Typst.Encode do
  def to_string(t)
end

defimpl Typst.Encode, for: Map do
  def to_string(map) when map_size(map) == 0 do
    "(:)"
  end

  def to_string(map) do
    "(#{Enum.map_join(map, ", ", fn {k, v} -> "#{String.Chars.BitString.to_string(k)}: #{Typst.Encode.to_string(v)}" end)})"
  end
end

defimpl Typst.Encode, for: List do
  def to_string(list) do
    "(#{Enum.map_join(list, ", ", &Typst.Encode.to_string/1)})"
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
