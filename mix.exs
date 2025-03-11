defmodule Typst.MixProject do
  use Mix.Project

  @source_url "http://github.com/Hermanverschooten/typst"
  @version "0.1.2"

  def project do
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
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
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
      extras: ["README.md"]
    ]
  end
end
