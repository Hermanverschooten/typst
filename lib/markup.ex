defprotocol Typst.Markup do
  @moduledoc """
  Protocol for encoding Elixir values into Typst markup context.

  This protocol is used by `Typst.Engine` for `<%| %>` expressions,
  converting Elixir values into content text suitable for Typst markup mode.

  ## Examples

      iex> Typst.Markup.encode("Hello")
      "Hello"

      iex> Typst.Markup.encode(42)
      "42"

  """

  @fallback_to_any true

  @doc "Encodes a value into Typst markup context."
  @spec encode(t) :: String.t()
  def encode(value)
end

defimpl Typst.Markup, for: BitString do
  def encode(value) when is_binary(value) do
    if String.printable?(value) do
      value
    else
      raise Protocol.UndefinedError,
        protocol: Typst.Markup,
        value: value,
        description: "cannot encode non-printable binary to Typst markup"
    end
  end
end

defimpl Typst.Markup, for: Any do
  def encode(value), do: String.Chars.to_string(value)
end
