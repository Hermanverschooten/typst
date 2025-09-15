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
