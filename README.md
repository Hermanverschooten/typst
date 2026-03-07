# Typst

[![Hex.pm](https://img.shields.io/hexpm/v/typst.svg)](https://hex.pm/packages/typst)
[![Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/typst)

Elixir bindings for the [Typst](https://typst.app) typesetting system, powered by a Rust NIF. Generate PDFs, PNGs, and SVGs from Typst markup directly in your Elixir application.

## Features

- **PDF generation** — `render_to_pdf/3`
- **PNG generation** — `render_to_png/3` (one image per page)
- **SVG generation** — `render_to_svg/3` (one SVG per page)
- **EEx templating** — use familiar Elixir templates to inject dynamic content
- **Table formatting** — struct-based API for building Typst tables (`Typst.Format.Table`)
- **Virtual file system** — pass in-memory assets (images, data) without touching disk
- **Font caching** — scanned fonts are cached across calls for fast repeated renders
- **Precompiled NIF** — no Rust toolchain required for most platforms

## Installation

Add `typst` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:typst, "~> 0.2"}
  ]
end
```

## Usage

### Basic rendering

```elixir
{:ok, pdf} = Typst.render_to_pdf("= Hello World")

{:ok, [png]} = Typst.render_to_png("= Hello World")

{:ok, [svg]} = Typst.render_to_svg("= Hello World")
```

### EEx templating

```elixir
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

{:ok, pdf} = Typst.render_to_pdf(
  ~S|#image(read("logo", encoding: none), width: 6cm)|,
  [],
  assets: [logo: logo]
)
```

### Typst-aware engine and `~TYPST` sigil

The standard EEx `<%= %>` tags convert values with `to_string/1`, which doesn't understand Typst syntax. The `Typst.Engine` provides automatic encoding through two protocols:

- `<%= expr %>` — encodes via `Typst.Code` (for function arguments: atoms become bare words, strings get quoted, lists become arrays, etc.)
- `<%| expr %>` — encodes via `Typst.Markup` (for content text: strings pass through, other types use `to_string/1`)

Both markers support `@variable` assigns syntax.

```elixir
EEx.eval_string(
  "#text(font: <%= @font %>)[<%| @name %>]",
  [assigns: %{font: "Roboto", name: "World"}],
  engine: Typst.Engine
)
# => ~S|#text(font: "Roboto")[World]|
```

For compile-time templates, use the `~TYPST` sigil which requires an `assigns` variable in scope:

```elixir
import Typst, only: :sigils

assigns = %{title: "Report", align: :center, items: [1, 2, 3]}

~TYPST"""
#set align(<%= @align %>)
= <%| @title %>
#list(<%= @items %>)
"""
# => "#set align(center)\n= Report\n#list((1, 2, 3))\n"
```

See `Typst.Code` for the full encoding reference table.

### Options

All render functions accept these options:

- `:extra_fonts` — list of directories to search for additional fonts
- `:root_dir` — root directory for resolving file paths (default: `"."`)
- `:assets` — list of `{name, binary}` pairs for the virtual file system
- `:trim` — trim blank lines left by EEx tags (default: `false`)
- `:cache_fonts` — cache scanned fonts across calls (default: `true`)
- `:pixels_per_pt` — pixels per pt unit, only for `render_to_png/3` (default: `1.0`)

## Documentation

Full documentation is available at [hexdocs.pm/typst](https://hexdocs.pm/typst).

## Cutting a new release

* Make the code changes
* Merge into main
* `git push`
* Tag the new version and push: `git tag v0.x.y && git push --tags`
* Wait for CI to build precompiled binaries
* `mix rustler_precompiled.download Typst.NIF --all --print`
* Checkout the tag: `git checkout v0.x.y`
* `mix hex.publish`
* `git checkout main`

## License

Apache-2.0
