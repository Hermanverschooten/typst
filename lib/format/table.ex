defmodule Typst.Format.Table do
  import Typst.Format

  @moduledoc """
  Creates a typst [`#table()`](https://typst.app/docs/reference/model/table) and implements the `String.Chars` protocol for easy EEx interpolation.
  To build more complex tables you can use the structs under this module like `Typst.Format.Table.Hline`

  ## Examples

      iex> alias Typst.Format.Table
      ...> %Table{columns: 2, content: [["hello", "world"], ["foo", "bar"]]} |> to_string()
      "#table(columns: 2, [hello], [world], [foo], [bar])"

      iex> alias Typst.Format.Table
      ...> alias Typst.Format.Table.Hline
      ...> import Typst.Format
      ...> %Table{columns: array(["1fr", "1fr"]), content: [["hello", "world"], %Hline{start: 1}, ["foo", "bar"]]} |> to_string()
      "#table(columns: (1fr, 1fr), [hello], [world], table.hline(start: 1), [foo], [bar])"
  """

  @enforce_keys [:content]
  defstruct [
    :content,
    :columns,
    :gutter,
    :row_gutter,
    :column_gutter,
    :fill,
    :align,
    :stroke,
    :inset,
    :rows
  ]

  defimpl String.Chars do
    def to_string(%Typst.Format.Table{} = table) do
      [
        "#table(",
        [
          if_set(table.columns, "columns: #{table.columns}"),
          if_set(table.rows, "rows: #{table.rows}"),
          if_set(table.gutter, "gutter: #{table.gutter}"),
          if_set(table.column_gutter, "column-gutter: #{table.column_gutter}"),
          if_set(table.row_gutter, "row-gutter: #{table.row_gutter}"),
          if_set(table.fill, "fill: #{table.fill}"),
          if_set(table.align, "align: #{table.align}"),
          if_set(table.stroke, "stroke: #{table.stroke}"),
          if_set(table.inset, "inset: #{table.inset}")
        ]
        |> Enum.reject(fn item -> item == [] end)
        |> Enum.intersperse(", ")
        |> maybe_append_separator(),
        Typst.Format.recurse(table.content),
        ")"
      ]
      |> IO.iodata_to_binary()
    end
  end

  defmodule Cell do
    @moduledoc """
    Creates a typst [`table.cell()`](https://typst.app/docs/reference/model/table/#definitions-cell) and implements the `String.Chars` protocol for easy EEx interpolation.

    ## Examples

        iex> alias Typst.Format.Table.Cell
        ...> %Cell{x: 2, content: ["hello", "world"]} |> to_string()
        "table.cell(x: 2, [hello], [world])"

    """

    @enforce_keys [:content]
    defstruct [
      :content,
      :x,
      :y,
      :colspan,
      :rowspan,
      :fill,
      :align,
      :stroke,
      :inset,
      :breakable
    ]

    defimpl String.Chars do
      def to_string(%Typst.Format.Table.Cell{} = cell) do
        [
          "table.cell(",
          [
            if_set(cell.x, "x: #{cell.x}"),
            if_set(cell.y, "y: #{cell.y}"),
            if_set(cell.colspan, "colspan: #{cell.colspan}"),
            if_set(cell.rowspan, "rowspan: #{cell.rowspan}"),
            if_set(cell.fill, "fill: #{cell.fill}"),
            if_set(cell.align, "align: #{cell.align}"),
            if_set(cell.stroke, "stroke: #{cell.stroke}"),
            if_set(cell.inset, "inset: #{cell.inset}"),
            if_set(cell.breakable, "breakable: #{cell.breakable}")
          ]
          |> Enum.reject(fn item -> item == [] end)
          |> Enum.intersperse(", ")
          |> maybe_append_separator(),
          Typst.Format.recurse(cell.content),
          ")"
        ]
        |> IO.iodata_to_binary()
      end
    end
  end

  defmodule Hline do
    @moduledoc """
    Creates a typst [`table.hline()`](https://typst.app/docs/reference/model/table/#definitions-hline) and implements the `String.Chars` protocol for easy EEx interpolation.

    ## Examples

        iex> alias Typst.Format.Table.Hline
        ...> %Hline{start: 2} |> to_string()
        "table.hline(start: 2)"

    """

    defstruct [:y, :start, :end, :stroke, :position]

    defimpl String.Chars do
      def to_string(%Typst.Format.Table.Hline{} = hline) do
        [
          "table.hline(",
          [
            if_set(hline.y, "y: #{hline.y}"),
            if_set(hline.start, "start: #{hline.start}"),
            if_set(hline.end, "end: #{hline.end}"),
            if_set(hline.stroke, "stroke: #{hline.stroke}"),
            if_set(hline.position, "position: #{hline.position}")
          ]
          |> Enum.reject(fn item -> item == [] end)
          |> Enum.intersperse(", "),
          ")"
        ]
        |> IO.iodata_to_binary()
      end
    end
  end

  defmodule Vline do
    @moduledoc """
    Creates a typst [`table.vline()`](https://typst.app/docs/reference/model/table/#definitions-vline) and implements the `String.Chars` protocol for easy EEx interpolation.

    ## Examples

        iex> alias Typst.Format.Table.Vline
        ...> %Vline{start: 2} |> to_string()
        "table.vline(start: 2)"

    """

    defstruct [:x, :start, :end, :stroke, :position]

    defimpl String.Chars do
      def to_string(%Typst.Format.Table.Vline{} = vline) do
        [
          "table.vline(",
          [
            if_set(vline.x, "x: #{vline.x}"),
            if_set(vline.start, "start: #{vline.start}"),
            if_set(vline.end, "end: #{vline.end}"),
            if_set(vline.stroke, "stroke: #{vline.stroke}"),
            if_set(vline.position, "position: #{vline.position}")
          ]
          |> Enum.reject(fn item -> item == [] end)
          |> Enum.intersperse(", "),
          ")"
        ]
        |> IO.iodata_to_binary()
      end
    end
  end

  defmodule Header do
    @moduledoc """
    Creates a typst [`table.header()`](https://typst.app/docs/reference/model/table/#definitions-header) and implements the `String.Chars` protocol for easy EEx interpolation.

    ## Examples

        iex> alias Typst.Format.Table.Header
        ...> %Header{repeat: false, content: ["hello", "world"]} |> to_string()
        "table.header(repeat: false, [hello], [world])"

    """

    @enforce_keys [:content]
    defstruct [:repeat, :content]

    defimpl String.Chars do
      def to_string(%Typst.Format.Table.Header{} = header) do
        [
          "table.header(",
          if_set(header.repeat, fn -> "repeat: #{header.repeat}, " end),
          Typst.Format.recurse(header.content),
          ")"
        ]
        |> IO.iodata_to_binary()
      end
    end
  end

  defmodule Footer do
    @moduledoc """
    Creates a typst [`table.footer()`](https://typst.app/docs/reference/model/table/#definitions-footer) and implements the `String.Chars` protocol for easy EEx interpolation.

    ## Examples

        iex> alias Typst.Format.Table.Footer
        ...> %Footer{repeat: false, content: ["hello", "world"]} |> to_string()
        "table.footer(repeat: false, [hello], [world])"

    """
    @enforce_keys [:content]
    defstruct [:repeat, :content]

    defimpl String.Chars do
      def to_string(%Typst.Format.Table.Footer{} = footer) do
        [
          "table.footer(",
          if_set(footer.repeat, fn -> "repeat: #{footer.repeat}, " end),
          Typst.Format.recurse(footer.content),
          ")"
        ]
        |> IO.iodata_to_binary()
      end
    end
  end
end
