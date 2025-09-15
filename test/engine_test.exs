defmodule Typst.EngineTest do
  use ExUnit.Case, async: true

  describe "Typst.Engine" do
    test "renders basic templates with interpolated values" do
      template = """
      Hello <%= "world" %>!
      """

      assert ~s|Hello "world"!\n| = EEx.eval_string(template, [], engine: Typst.Engine)
    end

    test "handles multiple interpolations in a single template" do
      template = """
      Name: <%= "Alice" %>
      Age: <%= 30 %>
      Items: <%= ["apple", "banana"] %>
      """

      expected = """
      Name: "Alice"
      Age: 30
      Items: ("apple", "banana")
      """

      assert expected == EEx.eval_string(template, [], engine: Typst.Engine)
    end

    test "works with variable bindings" do
      template = """
      User: <%= name %>
      Score: <%= score %>
      """

      result = EEx.eval_string(template, [name: "Bob", score: 100], engine: Typst.Engine)
      assert ~s|User: "Bob"\nScore: 100\n| = result
    end

    test "handles complex nested data structures" do
      data = %{
        "title" => "My Document",
        "sections" => [
          %{"name" => "Introduction", "pages" => 5},
          %{"name" => "Content", "pages" => 20}
        ]
      }

      template = """
      Document: <%= data %>
      """

      result = EEx.eval_string(template, [data: data], engine: Typst.Engine)
      assert String.starts_with?(result, "Document: (")
      assert String.contains?(result, "title:")
      assert String.contains?(result, "sections:")
    end

    test "preserves whitespace and formatting outside interpolations" do
      template = """
      = Title

      This is a paragraph with <%= "interpolated" %> content.

      - Item 1: <%= 42 %>
      - Item 2: <%= "test" %>
      """

      result = EEx.eval_string(template, [], engine: Typst.Engine)

      assert String.contains?(result, "= Title")
      assert String.contains?(result, "This is a paragraph with \"interpolated\" content.")
      assert String.contains?(result, "- Item 1: 42")
      assert String.contains?(result, "- Item 2: \"test\"")
    end
  end
end
