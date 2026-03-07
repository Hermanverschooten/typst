defmodule Typst.MarkupTest do
  use ExUnit.Case, async: true

  alias Typst.Markup

  doctest Typst.Markup

  describe "bitstring" do
    test "printable string" do
      assert Markup.encode("Hello World") == "Hello World"
    end

    test "empty string" do
      assert Markup.encode("") == ""
    end

    test "non-printable binary raises" do
      assert_raise Protocol.UndefinedError, fn ->
        Markup.encode(<<0xFF, 0xFE>>)
      end
    end
  end

  describe "any (fallback)" do
    test "integer" do
      assert Markup.encode(42) == "42"
    end

    test "float" do
      assert Markup.encode(3.14) == "3.14"
    end

    test "atom" do
      assert Markup.encode(:hello) == "hello"
    end
  end
end
