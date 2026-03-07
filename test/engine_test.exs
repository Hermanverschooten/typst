defmodule Typst.EngineTest do
  use ExUnit.Case, async: true

  alias Typst.Engine

  describe "code marker (<%= %>)" do
    test "encodes integer" do
      result = EEx.eval_string("<%= 42 %>", [], engine: Engine)
      assert result == "42"
    end

    test "encodes string with quotes" do
      result = EEx.eval_string(~s[<%= "hello" %>], [], engine: Engine)
      assert result == ~s["hello"]
    end

    test "encodes atom" do
      result = EEx.eval_string("<%= :center %>", [], engine: Engine)
      assert result == "center"
    end

    test "encodes nil" do
      result = EEx.eval_string("<%= nil %>", [], engine: Engine)
      assert result == "none"
    end

    test "encodes list" do
      result = EEx.eval_string("<%= [1, 2, 3] %>", [], engine: Engine)
      assert result == "(1, 2, 3)"
    end

    test "with surrounding text" do
      result = EEx.eval_string(~s[#set text(font: <%= "Roboto" %>)], [], engine: Engine)
      assert result == ~s[#set text(font: "Roboto")]
    end
  end

  describe "markup marker" do
    test "passes through string" do
      result = EEx.eval_string(~s[<%| "Hello" %>], [], engine: Engine)
      assert result == "Hello"
    end

    test "converts integer via Any fallback" do
      result = EEx.eval_string("<%| 42 %>", [], engine: Engine)
      assert result == "42"
    end

    test "with surrounding text" do
      result = EEx.eval_string(~s[Hello <%| "World" %>!], [], engine: Engine)
      assert result == "Hello World!"
    end
  end

  describe "plain marker (<% %>)" do
    test "executes code without output" do
      result = EEx.eval_string("<% _x = 1 %>hello", [], engine: Engine)
      assert result == "hello"
    end
  end

  describe "assigns" do
    test "code marker with assigns" do
      result =
        EEx.eval_string(
          "<%= @font %>",
          [assigns: %{font: "Roboto"}],
          engine: Engine
        )

      assert result == ~s["Roboto"]
    end

    test "markup marker with assigns" do
      result =
        EEx.eval_string(
          "<%| @name %>",
          [assigns: %{name: "World"}],
          engine: Engine
        )

      assert result == "World"
    end

    test "plain marker with assigns" do
      result =
        EEx.eval_string(
          "<% _x = @val %>ok",
          [assigns: %{val: 1}],
          engine: Engine
        )

      assert result == "ok"
    end

    test "mixed markers" do
      template = "#text(font: <%= @font %>)[<%| @name %>]"

      result =
        EEx.eval_string(
          template,
          [assigns: %{font: "Roboto", name: "World"}],
          engine: Engine
        )

      assert result == "#text(font: \"Roboto\")[World]"
    end
  end

  describe "sigil_TYPST" do
    import Typst, only: :sigils

    test "basic usage" do
      assigns = %{name: "World", font: "Roboto"}

      result = ~TYPST"#text(font: <%= @font %>)[<%| @name %>]"

      assert result == "#text(font: \"Roboto\")[World]"
    end

    test "multiline" do
      assigns = %{title: "Hello"}

      result = ~TYPST"""
      = <%| @title %>
      """

      assert result == "= Hello\n"
    end

    test "with code context encoding" do
      assigns = %{items: [1, 2, 3]}

      result = ~TYPST"#list(<%= @items %>)"

      assert result == "#list((1, 2, 3))"
    end
  end
end
