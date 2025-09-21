defmodule Typst.EngineTest do
  use ExUnit.Case, async: true

  test "renders basic templates with interpolated values" do
    template = """
    Hello <%| "world" %>!
    """

    assert ~s|Hello world!\n| = EEx.eval_string(template, [], engine: Typst.Engine)
  end

  test "code and markup context supported" do
    template = """
    #text(font: <%= "Helvetica Neue" %>)[
      = Background
      In the case of <%| "glaciers" %>, fluid
      dynamics principles can be used
      to understand how the movement
      and behaviour of the ice is
      influenced by factors such as
      temperature, pressure, and the
      presence of other fluids (such as
      water).
    ]
    """

    assert """
           #text(font: "Helvetica Neue")[
             = Background
             In the case of glaciers, fluid
             dynamics principles can be used
             to understand how the movement
             and behaviour of the ice is
             influenced by factors such as
             temperature, pressure, and the
             presence of other fluids (such as
             water).
           ]
           """ = EEx.eval_string(template, [], engine: Typst.Engine)
  end

  test "works with assigns" do
    template = """
    #text(font: <%= @font %>)[
      = Introduction
      In this report, we will explore the
      various factors that influence _<%| @topic %>_
      in glaciers and how they
      contribute to the formation and
      behaviour of these natural structures.
    ]
    """

    assigns = [font: "Helvetica Neue", topic: "fluid dynamics"]

    assert """
           #text(font: "Helvetica Neue")[
             = Introduction
             In this report, we will explore the
             various factors that influence _fluid dynamics_
             in glaciers and how they
             contribute to the formation and
             behaviour of these natural structures.
           ]
           """ = EEx.eval_string(template, [assigns: assigns], engine: Typst.Engine)
  end

  test "raises on missing assign" do
    template = """
    #text(font: <%= @font %>)[
      = Introduction
      In this report, we will explore the
      various factors that influence _<%| @topic %>_
      in glaciers and how they
      contribute to the formation and
      behaviour of these natural structures.
    ]
    """

    assigns = [topic: "fluid dynamics"]

    assert_raise ArgumentError,
                 """
                 assign @font not available in template.

                 Please make sure all proper assigns have been set. If this
                 is a child template, ensure assigns are given explicitly by
                 the parent template as they are not automatically forwarded.

                 Available assigns: [:topic]
                 """,
                 fn ->
                   EEx.eval_string(template, [assigns: assigns], engine: Typst.Engine)
                 end
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
    Document: <%= @data %>
    """

    result = EEx.eval_string(template, [assigns: [data: data]], engine: Typst.Engine)
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
