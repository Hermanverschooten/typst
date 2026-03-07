defmodule Typst.CodeTest do
  use ExUnit.Case, async: true

  alias Typst.Code

  doctest Typst.Code

  describe "integers" do
    test "positive" do
      assert Code.encode(42) == "42"
    end

    test "negative" do
      assert Code.encode(-1) == "-1"
    end

    test "zero" do
      assert Code.encode(0) == "0"
    end
  end

  describe "floats" do
    test "positive" do
      assert Code.encode(3.14) == "3.14"
    end

    test "negative" do
      assert Code.encode(-2.5) == "-2.5"
    end
  end

  describe "atoms" do
    test "regular atom" do
      assert Code.encode(:center) == "center"
    end

    test "true" do
      assert Code.encode(true) == "true"
    end

    test "false" do
      assert Code.encode(false) == "false"
    end

    test "nil" do
      assert Code.encode(nil) == "none"
    end
  end

  describe "strings" do
    test "simple string" do
      assert Code.encode("hello") == "\"hello\""
    end

    test "escapes backslash" do
      assert Code.encode("a\\b") == "\"a\\\\b\""
    end

    test "escapes double quote" do
      assert Code.encode("say \"hi\"") == "\"say \\\"hi\\\"\""
    end

    test "escapes newline" do
      assert Code.encode("line1\nline2") == "\"line1\\nline2\""
    end

    test "escapes tab" do
      assert Code.encode("col1\tcol2") == "\"col1\\tcol2\""
    end

    test "escapes carriage return" do
      assert Code.encode("a\rb") == "\"a\\rb\""
    end

    test "non-printable binary encodes as bytes" do
      assert Code.encode(<<0, 1, 2, 3>>) == "bytes(0, 1, 2, 3)"
    end
  end

  describe "lists" do
    test "simple list" do
      assert Code.encode([1, 2, 3]) == "(1, 2, 3)"
    end

    test "empty list" do
      assert Code.encode([]) == "()"
    end

    test "keyword list" do
      assert Code.encode(a: 1, b: 2) == "(a: 1, b: 2)"
    end

    test "nested values" do
      assert Code.encode([:center, "hello"]) == "(center, \"hello\")"
    end
  end

  describe "maps" do
    test "empty map" do
      assert Code.encode(%{}) == "(:)"
    end

    test "map with atom keys" do
      result = Code.encode(%{a: 1})
      assert result == "(a: 1)"
    end

    test "map with string keys" do
      result = Code.encode(%{"name" => "Alice"})
      assert result == "(name: \"Alice\")"
    end
  end

  describe "tuples" do
    test "label tuple" do
      assert Code.encode({:label, :intro}) == "<intro>"
    end

    test "label with string" do
      assert Code.encode({:label, "chapter-1"}) == "<chapter-1>"
    end
  end

  describe "dates and times" do
    test "date" do
      assert Code.encode(~D[2024-01-15]) ==
               "datetime(year: 2024, month: 1, day: 15)"
    end

    test "time" do
      assert Code.encode(~T[13:45:00]) ==
               "datetime(hour: 13, minute: 45, second: 0)"
    end

    test "naive datetime" do
      assert Code.encode(~N[2024-01-15 13:45:00]) ==
               "datetime(year: 2024, month: 1, day: 15, hour: 13, minute: 45, second: 0)"
    end

    test "datetime" do
      dt = DateTime.new!(~D[2024-01-15], ~T[13:45:00], "Etc/UTC")

      assert Code.encode(dt) ==
               "datetime(year: 2024, month: 1, day: 15, hour: 13, minute: 45, second: 0)"
    end
  end

  describe "regex" do
    test "simple regex" do
      assert Code.encode(~r/foo/) == "regex(`foo`.text)"
    end

    test "regex with special chars" do
      assert Code.encode(~r/\d+/) == "regex(`\\d+`.text)"
    end
  end

  if Elixir.Code.ensure_loaded?(Decimal) do
    describe "decimal" do
      test "encodes decimal" do
        assert Code.encode(Decimal.new("1.5")) == "decimal(\"1.5\")"
      end
    end
  end
end
