defmodule Typst.FormatTest do
  use ExUnit.Case

  import Typst.Format
  doctest Typst.Format

  test "bold" do
    assert "*hello*" == Typst.render_to_string("<%= hello %>", hello: bold("hello"))
  end

  test "content" do
    assert "[hello]" == Typst.render_to_string("<%= hello %>", hello: content("hello"))
  end

  test "array" do
    assert "(hello, world)" ==
             Typst.render_to_string("<%= hello %>", hello: array(["hello", "world"]))
  end
end
