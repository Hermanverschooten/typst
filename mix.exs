defmodule Typst.MixProject do
  use Mix.Project

  @source_url "https://github.com/Hermanverschooten/typst"
  @version "0.2.1"

  @nerves_rust_target_triple_mapping %{
    "armv6-nerves-linux-gnueabihf": "arm-unknown-linux-gnueabihf",
    "armv7-nerves-linux-gnueabihf": "armv7-unknown-linux-gnueabihf",
    "aarch64-nerves-linux-gnu": "aarch64-unknown-linux-gnu",
    "x86_64-nerves-linux-musl": "x86_64-unknown-linux-musl"
  }

  def project do
    if is_binary(System.get_env("NERVES_SDK_SYSROOT")) do
      components =
        System.get_env("CC")
        |> tap(&System.put_env("RUSTFLAGS", "-C linker=#{&1}"))
        |> Path.basename()
        |> String.split("-")

      target_triple =
        components
        |> Enum.slice(0, Enum.count(components) - 1)
        |> Enum.join("-")

      mapping = Map.get(@nerves_rust_target_triple_mapping, String.to_atom(target_triple))

      if is_binary(mapping) do
        System.put_env("RUSTLER_TARGET", mapping)
      end
    end

    [
      app: :typst,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description: "Elixir bindings for typst",
      package: package(),

      # Docs
      name: "Typst",
      source_url: @source_url,
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rustler, ">= 0.0.0", optional: true},
      {:rustler_precompiled, "~> 0.8"},
      {:ex_doc, "~> 0.39", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "Github" => @source_url,
        "Changelog" => "#{@source_url}/blob/v#{@version}/CHANGELOG.md"
      },
      exclude_patterns: [
        "native/typst_nif/target",
        "priv/native/libtypst_nif.so"
      ],
      files: [
        "lib",
        "native",
        "checksum-*.exs",
        "priv/fonts",
        ".formatter.exs",
        "README.md",
        "LICENSE",
        "mix.exs"
      ]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      groups_for_modules: [
        Table: [
          Typst.Format.Table,
          Typst.Format.Table.Cell,
          Typst.Format.Table.Hline,
          Typst.Format.Table.Vline,
          Typst.Format.Table.Header,
          Typst.Format.Table.Footer
        ]
      ],
      nest_modules_by_prefix: [
        Typst.Format.Table,
        Typst.Format.Table.Cell,
        Typst.Format.Table.Hline,
        Typst.Format.Table.Vline,
        Typst.Format.Table.Header,
        Typst.Format.Table.Footer
      ]
    ]
  end
end
