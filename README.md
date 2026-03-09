# Typst

[![Hex.pm](https://img.shields.io/hexpm/v/typst.svg)](https://hex.pm/packages/typst)
[![Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/typst)

Elixir bindings for the [Typst](https://typst.app) typesetting system, powered by a Rust NIF. Generate PDFs, PNGs, and SVGs from Typst markup directly in your Elixir application.

## Features

- **PDF generation** — `to_pdf/2` / `render_to_pdf/3`
- **PNG generation** — `to_png/2` / `render_to_png/3` (one image per page)
- **SVG generation** — `to_svg/2` / `render_to_svg/3` (one SVG per page)
- **EEx templating** — use familiar Elixir templates to inject dynamic content
- **`~TYPST` sigil** — compile-time EEx with automatic Typst encoding
- **Table formatting** — struct-based API for building Typst tables (`Typst.Format.Table`)
- **Virtual file system** — pass in-memory assets (images, data) without touching disk
- **Font caching** — scanned fonts are cached across calls for fast repeated renders
- **Precompiled NIF** — no Rust toolchain required for most platforms

## Installation

Add `typst` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:typst, "~> 0.3"}
  ]
end
```

## Usage

There are two families of compilation functions:

| | Plain strings | EEx templates |
|---|---|---|
| **PDF** | `Typst.to_pdf/2` | `Typst.render_to_pdf/3` |
| **PNG** | `Typst.to_png/2` | `Typst.render_to_png/3` |
| **SVG** | `Typst.to_svg/2` | `Typst.render_to_svg/3` |

Use **`to_*`** when your markup is already a complete string — either static markup, output from the `~TYPST` sigil, or a `.typ` file read from disk. Use **`render_to_*`** when the **template itself** is a runtime string containing EEx directives (e.g. loaded from a database or file) that still needs to be evaluated with bindings.

### Plain strings with `to_*`

```elixir
{:ok, pdf} = Typst.to_pdf("= Hello World")

{:ok, [png]} = Typst.to_png("= Hello World")

{:ok, [svg]} = Typst.to_svg("= Hello World")

{:ok, pdf} = File.read!("report.typ") |> Typst.to_pdf()
```

### `~TYPST` sigil

The `~TYPST` sigil compiles the EEx template structure at compile-time, but the `assigns` data is evaluated at runtime — so it works perfectly with dynamic data. Since it produces a plain string, pair it with `to_*` functions (not `render_to_*`, which would run EEx a second time):

```elixir
defmodule MyApp.Report do
  import Typst, only: :sigils

  def render(assigns) do
    ~TYPST"""
    #set align(<%= @align %>)
    = <%| @title %>
    #list(<%= @items %>)
    """
  end
end

MyApp.Report.render(%{title: "Report", align: :center, items: [1, 2, 3]})
|> Typst.to_pdf()
```

The sigil provides two markers through the `Typst.Engine`:

- `<%= expr %>` — encodes via `Typst.Code` (for function arguments: atoms become bare words, strings get quoted, lists become arrays, etc.)
- `<%| expr %>` — encodes via `Typst.Markup` (for content text: strings pass through, other types use `to_string/1`)

Both markers support `@variable` assigns syntax. You can also use `Typst.Engine` directly with `EEx.eval_string/3`:

```elixir
EEx.eval_string(
  "#text(font: <%= @font %>)[<%| @name %>]",
  [assigns: %{font: "Roboto", name: "World"}],
  engine: Typst.Engine
)
# => ~S|#text(font: "Roboto")[World]|
```

See `Typst.Code` for the full encoding reference table.

### EEx templates with `render_to_*`

Use these when the **template itself** is not known at compile-time — for example, a template stored in a database or loaded from a user-provided file:

```elixir
template = File.read!("report.typ.eex")
{:ok, pdf} = Typst.render_to_pdf(template, name: "Acme Corp")

{:ok, pdf} = Typst.render_to_pdf(
  "= Report for <%= name %>\nDate: <%= date %>",
  name: "Acme Corp",
  date: "2026-03-07"
)
```

### Tables

```elixir
alias Typst.Format.Table
alias Typst.Format.Table.Header

table = %Table{
  columns: 3,
  content: [
    %Header{repeat: true, content: ["Name", "Qty", "Price"]},
    ["Widget", "10", "$5.00"],
    ["Gadget", "3", "$12.50"]
  ]
}

{:ok, pdf} = Typst.render_to_pdf("<%= table %>", table: table)
```

### Virtual assets

```elixir
logo = File.read!("logo.svg")

{:ok, pdf} = Typst.to_pdf(
  ~S|#image(read("logo", encoding: none), width: 6cm)|,
  assets: [logo: logo]
)
```

### Options

All functions accept these options:

- `:extra_fonts` — list of directories to search for additional fonts
- `:root_dir` — root directory for resolving file paths (default: `"."`)
- `:assets` — list of `{name, binary}` pairs for the virtual file system
- `:cache_fonts` — cache scanned fonts across calls (default: `true`)
- `:pixels_per_pt` — pixels per pt unit, only for PNG functions (default: `1.0`)

The `render_to_*` functions additionally accept:

- `:trim` — trim blank lines left by EEx tags (default: `false`)

## Documentation

Full documentation is available at [hexdocs.pm/typst](https://hexdocs.pm/typst).


## License

Apache-2.0
