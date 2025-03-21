defmodule TypstTest do
  use ExUnit.Case

  doctest Typst

  test "smoke test" do
    assert "= Hello world" == Typst.render_to_string("= Hello <%= name %>", name: "world")

    {:ok, pdf} = Typst.render_to_pdf("= Hello <%= name %>", name: "world")
    assert is_binary(pdf)
  end
end
