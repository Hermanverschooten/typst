defprotocol Typst.Markup do
  @fallback_to_any true
  def encode(t)
end

defimpl Typst.Markup, for: BitString do
  def encode(str) do
    if String.printable?(str) do
      str
    else
      raise ArgumentError, "Cannot print non-printable string to typst markup"
    end
  end
end

defimpl Typst.Markup, for: Any do
  def encode(data) do
    String.Chars.to_string(data)
  end
end
