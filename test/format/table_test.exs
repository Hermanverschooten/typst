defmodule Typst.Format.TableTest do
  use ExUnit.Case, async: true
  import Typst, only: :sigils
  import Typst.Format
  alias Typst.Format.Table
  alias Typst.Format.Table.{Hline, Header}

  doctest Typst.Format.Table

  test "table" do
    assigns = %{
      table: %Table{
        columns: 2,
        content: [
          %Header{content: ["col1", "col2"], repeat: false},
          ["*hello*", "world"],
          %Hline{start: 1},
          ["*foo*", "bar"]
        ]
      }
    }

    template = ~TYPST"""
    <%| table %>
    """

    assert "#table(columns: 2, table.header(repeat: false, [col1], [col2]), [*hello*], [world], table.hline(start: 1), [*foo*], [bar])" ==
             template
  end

  test "cell" do
    alias Typst.Format.Table.Cell

    cell =
      %Cell{colspan: 2, align: "right", content: "foo"}

    expected =
      "table.cell(colspan: 2, align: right, [foo])"

    assert expected == Typst.render_to_string("<%= cell %>", cell: cell)
    {:ok, _pdf} = Typst.render_to_pdf("<%= cell %>", cell: cell)
  end

  test "hline" do
    alias Typst.Format.Table.Hline

    hline =
      %Hline{start: 1, end: 3}

    expected =
      "table.hline(start: 1, end: 3)"

    assert expected == Typst.render_to_string("<%= hline %>", hline: hline)
    {:ok, _pdf} = Typst.render_to_pdf("<%= hline %>", hline: hline)
  end

  test "vline" do
    alias Typst.Format.Table.Vline

    vline =
      %Vline{start: 1, end: 3}

    expected =
      "table.vline(start: 1, end: 3)"

    assert expected == Typst.render_to_string("<%= vline %>", vline: vline)
    {:ok, _pdf} = Typst.render_to_pdf("<%= vline %>", vline: vline)
  end

  test "header" do
    alias Typst.Format.Table.Header

    header =
      %Header{repeat: false, content: ["foo", "bar"]}

    expected =
      "table.header(repeat: false, [foo], [bar])"

    assert expected == Typst.render_to_string("<%= header %>", header: header)
    {:ok, _pdf} = Typst.render_to_pdf("<%= header %>", header: header)
  end

  test "footer" do
    alias Typst.Format.Table.Footer

    footer =
      %Footer{repeat: false, content: ["foo", "bar"]}

    expected =
      "table.footer(repeat: false, [foo], [bar])"

    assert expected == Typst.render_to_string("<%= footer %>", footer: footer)
    {:ok, _pdf} = Typst.render_to_pdf("<%= footer %>", footer: footer)
  end
end
