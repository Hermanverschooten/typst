defprotocol Typst.Markup do
  @moduledoc """
  Protocol for encoding Elixir values into Typst markup context.

  This protocol is used by `Typst.Engine` for `<%| %>` expressions,
  converting Elixir values into content text suitable for Typst markup mode.

  Unlike `Typst.Code`, this protocol uses `@fallback_to_any true`, so any
  value that implements `String.Chars` (including `Typst.Format.Table` structs)
  works automatically.

  > #### No escaping {: .warning}
  >
  > Strings are inserted as-is without escaping Typst markup characters.
  > If you are inserting user-provided text, use `Typst.Format.escape/1`
  > to prevent special characters (`*`, `#`, `@`, etc.) from being
  > interpreted as Typst syntax.

  ## Custom implementations

  Both `Typst.Markup` and `Typst.Code` are protocols, so you can implement
  them for your own types or format values before passing them in. For example,
  for locale-aware number formatting:

      <%| MyApp.Cldr.Number.to_string!(@price) %>

  ## Encoding reference

  | Type | Behavior |
  |------|----------|
  | Printable binary | returned as-is |
  | Non-printable binary | raises `Protocol.UndefinedError` |
  | Any other type | delegates to `String.Chars.to_string/1` |

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
