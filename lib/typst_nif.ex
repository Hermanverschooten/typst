defmodule Typst.NIF do
  @moduledoc false

  defmodule PdfOptions do
    @moduledoc false
    defstruct standards: []
  end

  mix_config =
    Mix.Project.config()

  version = mix_config[:version]

  github_url =
    mix_config[:package][:links]["Github"]

  # Since Rustler 0.27.0, we need to change manually the mode for each env.
  # We want "debug" in dev and test because it's faster to compile.
  mode = if Mix.env() in [:dev, :test], do: :debug, else: :release

  use RustlerPrecompiled,
    otp_app: :typst,
    crate: "typst_nif",
    version: version,
    base_url: "#{github_url}/releases/download/v#{version}",
    nif_versions: ["2.15", "2.17"],
    mode: mode,
    target: System.get_env("RUSTLER_TARGET")

  def compile_pdf(_content, _root_dir, _font_paths, _assets, _cache_fonts, _pdf_opts),
    do: :erlang.nif_error(:nif_not_loaded)

  def compile_png(_content, _root_dir, _font_paths, _pixels_per_pt, _assets, _cache_fonts),
    do: :erlang.nif_error(:nif_not_loaded)

  def compile_svg(_content, _root_dir, _font_paths, _assets, _cache_fonts),
    do: :erlang.nif_error(:nif_not_loaded)
end
