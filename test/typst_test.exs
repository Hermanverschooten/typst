defmodule TypstTest do
  use ExUnit.Case, async: true
  import Typst, only: :sigils

  doctest Typst

  test "smoke test" do
    assigns = %{
      font: "Roboto",
      name: "world"
    }

    template = ~TYPST"""
    #text(font: <%= @font %>)[
      = Hello <%| @name %>
    ]
    """

    assert """
           #text(font: "Roboto")[
             = Hello world
           ]
           """ == template

    {:ok, pdf} = Typst.render_to_pdf(template)
    assert is_binary(pdf)
  end
end
