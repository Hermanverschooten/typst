defmodule Typst.EncodeTest do
  use ExUnit.Case, async: true
  alias Typst.Encode

  describe "to_string/1 for List" do
    test "empty list" do
      assert "()" = Encode.to_string([])
    end

    test "list of integers" do
      assert "(1, 2, 3)" = Encode.to_string([1, 2, 3])
    end

    test "list of strings" do
      assert ~S|("a", "b", "c")| = Encode.to_string(["a", "b", "c"])
    end

    test "list of mixed subtypes" do
      assert ~S|("a", "b", 3)| = Encode.to_string(["a", "b", 3])
    end
  end

  describe "to_string/1 for Map" do
    test "empty map" do
      assert "(:)" = Encode.to_string(%{})
    end

    test "map of strings" do
      assert ~S|(a: "b", c: "d")| = Encode.to_string(%{"a" => "b", "c" => "d"})
    end

    test "map of integers" do
      assert ~S|(a: 1, b: 2)| = Encode.to_string(%{"a" => 1, "b" => 2})
    end

    test "map of mixed types" do
      assert ~s|(a: "x", b: 2)| = Encode.to_string(%{"a" => "x", "b" => 2})
    end
  end

  describe "to_string/1 for BitString" do
    test "simple string is properly quoted and escaped" do
      assert ~S|"hello world"| = Encode.to_string("hello world")
    end

    test "strings with special characters are properly escaped" do
      result =
        Encode.to_string([
          "hello \"world\"",
          "back\\slash",
          "new\nline",
          "tab\there",
          "carriage\rreturn",
          "both\t\r\n"
        ])

      assert ~S|("hello \"world\"", "back\\slash", "new\nline", "tab\there", "carriage\rreturn", "both\t\r\n")| =
               result
    end

    test "unicode characters" do
      result = Encode.to_string(["Hello 🌍", "café", "naïve", "résumé", "тест", "🚀✨"])
      assert ~S|("Hello 🌍", "café", "naïve", "résumé", "тест", "🚀✨")| = result
    end
  end

  describe "to_string/1 for Atom" do
    test "atoms can be encoded" do
      assert "test" = Encode.to_string(:test)
    end
  end

  describe "to_string/1 for Tuple" do
    test "labeled tuples are encoded as typst labels" do
      assert "<test>" = Encode.to_string({:label, :test})
    end
  end

  describe "to_string/1 for Integer" do
    test "integers can be encoded" do
      assert "42" = Encode.to_string(42)
    end
  end

  describe "to_string/1 for Float" do
    test "floats can be encoded" do
      assert "0.1" = Encode.to_string(0.1)
    end
  end

  describe "to_string/1 for Decimal" do
    test "decimals can be encoded" do
      assert ~S|decimal("0.1")| = Encode.to_string(Decimal.new("0.1"))
    end
  end

  describe "to_string/1 nested" do
    test "nested structures work correctly" do
      data = %{"users" => [%{"name" => "Alice", "age" => 30}, %{"name" => "Bob", "age" => 25}]}

      assert ~S|(users: ((age: 30, name: "Alice"), (age: 25, name: "Bob")))| ==
               Encode.to_string(data)
    end
  end
end
