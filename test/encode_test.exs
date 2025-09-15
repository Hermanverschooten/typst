defmodule Typst.EncodeTest do
  use ExUnit.Case, async: true

  describe "Typst.Encode protocol" do
    test "list of integers" do
      assert "(1, 2, 3)" = Typst.Encode.to_string([1, 2, 3])
    end

    test "empty map" do
      assert "(:)" = Typst.Encode.to_string(%{})
    end

    test "map of strings" do
      assert "(a: \"b\", c: \"d\")" = Typst.Encode.to_string(%{"a" => "b", "c" => "d"})
    end

    test "list of strings" do
      assert "(\"a\", \"b\", \"c\")" = Typst.Encode.to_string(["a", "b", "c"])
    end

    test "strings with special characters are properly escaped" do
      result = Typst.Encode.to_string(["hello \"world\"", "back\\slash", "new\nline"])
      assert "(\"hello \\\"world\\\"\", \"back\\\\slash\", \"new\\nline\")" = result
    end

    test "strings with tabs and carriage returns are properly escaped" do
      result = Typst.Encode.to_string(["tab\there", "carriage\rreturn", "both\t\r\n"])
      assert "(\"tab\\there\", \"carriage\\rreturn\", \"both\\t\\r\\n\")" = result
    end

    test "empty string and strings with only special characters" do
      result = Typst.Encode.to_string(["", "\n", "\t", "\r\n", "\\"])
      assert "(\"\", \"\\n\", \"\\t\", \"\\r\\n\", \"\\\\\")" = result
    end

    test "unicode characters do not need escaping" do
      result = Typst.Encode.to_string(["Hello 🌍", "café", "naïve", "résumé", "тест", "🚀✨"])
      assert "(\"Hello 🌍\", \"café\", \"naïve\", \"résumé\", \"тест\", \"🚀✨\")" = result
    end

    test "integers are encoded as strings" do
      assert "42" = Typst.Encode.to_string(42)
    end

    test "single string is properly quoted and escaped" do
      assert "\"hello world\"" = Typst.Encode.to_string("hello world")
    end

    test "atoms are encoded as strings" do
      assert "test" = Typst.Encode.to_string(:test)
    end

    test "labeled tuples are encoded with angle brackets" do
      assert "<test>" = Typst.Encode.to_string({:label, :test})
    end

    test "nested structures work correctly" do
      data = %{"users" => [%{"name" => "Alice", "age" => 30}, %{"name" => "Bob", "age" => 25}]}
      result = Typst.Encode.to_string(data)

      expected =
        "(users: ((age: 30, name: \"Alice\"), (age: 25, name: \"Bob\")))"

      assert expected == result
    end
  end
end
