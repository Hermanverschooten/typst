defmodule Typst.CodeTest do
  use ExUnit.Case, async: true
  alias Typst.Code

  describe "encode/1 for List" do
    test "empty list" do
      assert "()" = Code.encode([])
    end

    test "list of integers" do
      assert "(1, 2, 3)" = Code.encode([1, 2, 3])
    end

    test "list of strings" do
      assert ~S|("a", "b", "c")| = Code.encode(["a", "b", "c"])
    end

    test "list of mixed subtypes" do
      assert ~S|("a", "b", 3)| = Code.encode(["a", "b", 3])
    end

    test "keyword list" do
      assert ~S|(a: "b", c: "d")| = Code.encode(a: "b", c: "d")
    end
  end

  describe "encode/1 for Map" do
    test "empty map" do
      assert "(:)" = Code.encode(%{})
    end

    test "map of strings" do
      assert ~S|(a: "b", c: "d")| = Code.encode(%{"a" => "b", "c" => "d"})
    end

    test "map of integers" do
      assert ~S|(a: 1, b: 2)| = Code.encode(%{"a" => 1, "b" => 2})
    end

    test "map of mixed types" do
      assert ~s|(a: "x", b: 2)| = Code.encode(%{"a" => "x", "b" => 2})
    end

    test "atom keys" do
      assert ~S|(c: "d", a: "b")| = Code.encode(%{a: "b", c: "d"})
    end
  end

  describe "encode/1 for BitString" do
    test "empty string" do
      assert ~S|""| = Code.encode("")
    end

    test "simple string is properly quoted and escaped" do
      assert ~S|"hello world"| = Code.encode("hello world")
    end

    test "strings with special characters are properly escaped" do
      result =
        Code.encode([
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
      result = Code.encode(["Hello 🌍", "café", "naïve", "résumé", "тест", "🚀✨"])
      assert ~S|("Hello 🌍", "café", "naïve", "résumé", "тест", "🚀✨")| = result
    end

    test "encode as bytes" do
      assert ~S|bytes(0, 1, 2, 3)| = Code.encode(<<0, 1, 2, 3>>)
    end
  end

  describe "encode/1 for Atom" do
    test "atoms can be encoded" do
      assert "test" = Code.encode(:test)
    end
  end

  describe "encode/1 for Tuple" do
    test "labeled tuples are encoded as typst labels" do
      assert "<test>" = Code.encode({:label, :test})
    end
  end

  describe "encode/1 for Date" do
    test "dates can be encoded" do
      assert "datetime(year: 2025, month: 9, day: 20)" = Code.encode(~D[2025-09-20])
    end
  end

  describe "encode/1 for Time" do
    test "times can be encoded" do
      assert "datetime(hour: 10, minute: 11, second: 12)" = Code.encode(~T[10:11:12])
    end

    test "does not support subsecond values" do
      assert "datetime(hour: 10, minute: 11, second: 12)" = Code.encode(~T[10:11:12.013])
    end
  end

  describe "encode/1 for NaiveDateTime" do
    test "naive datetimes can be encoded" do
      assert "datetime(year: 2025, month: 9, day: 20, hour: 10, minute: 11, second: 12)" =
               Code.encode(~N[2025-09-20 10:11:12])
    end
  end

  describe "encode/1 for DateTime" do
    test "datetimes drop any timezone related information" do
      assert "datetime(year: 2025, month: 9, day: 20, hour: 10, minute: 11, second: 12)" =
               Code.encode(~U[2025-09-20 10:11:12Z])
    end
  end

  describe "encode/1 for Regex" do
    test "regexes can be encoded" do
      assert ~S|regex(`\d+\.\d+\.\d+`.text)| = Code.encode(~r/\d+\.\d+\.\d+/)
    end
  end

  describe "encode/1 for Integer" do
    test "integers can be encoded" do
      assert "42" = Code.encode(42)
    end
  end

  describe "encode/1 for Float" do
    test "floats can be encoded" do
      assert "0.1" = Code.encode(0.1)
    end
  end

  describe "encode/1 for Decimal" do
    test "decimals can be encoded" do
      assert ~S|decimal("0.1")| = Code.encode(Decimal.new("0.1"))
    end
  end

  describe "encode/1 nested" do
    test "nested structures work correctly" do
      data = %{"users" => [%{"name" => "Alice", "age" => 30}, %{"name" => "Bob", "age" => 25}]}

      assert ~S|(users: ((age: 30, name: "Alice"), (age: 25, name: "Bob")))| ==
               Code.encode(data)
    end
  end
end
