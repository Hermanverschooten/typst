defmodule Typst.Format.Table do
  import Typst.Format

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
