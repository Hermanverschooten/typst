# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `:pdf_standards` option to `render_to_pdf/3` for PDF/A compliance (e.g. `"a-2b"`, `"a-4"`). Thank you [adrian-mihai-olaru](https://github.com/adrian-mihai-olaru).

## [v0.3.4] - 2026-04-14

### Added
- Precompiled NIF binaries for NIF version 2.17 (OTP 28 support)

## [v0.3.3] - 2026-03-28

### Fixed
- Trailing comma in table output when content is empty (e.g. `#table(columns: 2, )` → `#table(columns: 2)`)
- NIF panic when font cache mutex is poisoned by a prior thread panic
- NIF panic on out-of-bounds font index access
- HTTP package downloads could hang indefinitely — added 30-second timeout

### Changed
- Updated `rustler_precompiled` 0.8.4 → 0.9.0
- Updated `comemo` 0.4 → 0.5 (eliminates duplicate dependency with typst internals)
- Updated Rust NIF `rustler` crate 0.36 → 0.37

## [v0.3.2] - 2026-03-18

### Changed
- Move fonts from `priv/fonts/` to `assets/fonts/` and copy to priv at compile time. Thank you [fhunleth](https://github.com/fhunleth).

## [v0.3.1] - 2026-03-07

### Fixed
- Memory leak caused by comemo memoization cache retaining ~30 compilations worth of data. Since each NIF call creates a fresh World, the cache was never reused.

## [v0.3.0] - 2026-03-07

### Added
- `render_to_svg/3` and `render_to_svg!/3` for SVG output, one per page
- `Typst.Format.escape/1` for escaping special Typst markup characters in user-provided text
- Documentation with examples for `Typst.Format` public functions
- Improved README with feature overview, usage examples, and options

### Removed (Breaking)
- `Typst.Format.table_content/1` — use `%Typst.Format.Table{}` instead

### Fixed
- Cell typespec missing `:inset` field
- Header and Footer using inconsistent separator pattern

## [v0.2.7] - 2026-03-07

- Cache the Typst standard library, HTTP agent and cache directory as global statics to further reduce memory usage and improve performance across repeated renders.
- Run NIF functions on dirty CPU schedulers to prevent blocking the BEAM.

## [v0.2.6] - 2026-03-06

Add font caching to avoid redundant font scanning across calls, improving performance for repeated renders.

## [v0.2.5] - 2026-03-04

Released due to a problem with source being out-of-sync with the released version.

## [v0.2.4] - 2026-03-04 - RETIRED

Fix memory leak caused by never evicting the comemo memoization cache after Typst compilation.

## [v0.2.3] - 2026-02-24

Added `:trim` option to `render_to_string/3`, `render_to_pdf/3`, and `render_to_png/3` to remove blank lines left by EEx tags. Defaults to `false`.

Updated dependencies: ex_doc 0.39.3 → 0.40.1, rustler 0.37.1 → 0.37.3.

## [v0.2.2] - 2025-12-13

Updated Typst to version 0.14.2 which includes a critical security fix for a use-after-free bug in the wasmi WebAssembly runtime.

## [v0.2.1] - 2025-12-09

Updated Typst to version 0.14.1. Thank you [kevinschweikert](https://github.com/kevinschweikert).
Fixed GitHub source URL in mix.exs. Thank you [Hugo Baraúna](https://github.com/hugobarauna).

## [v0.2.0] - 2025-10-25

Updated Typst to version 0.14 and added support for virtual files. Thank you [kevinschweikert](https://github.com/kevinschweikert).

## [v0.1.7] - 2025-09-21

Allow rendering to both PDF and PNG. Thank you [gworkman](https://github.com/gworkman).

## [v0.1.6] - 2025-09-20

Expand errors to return the location and source code.

## [v0.1.5] - 2025-06-09

Allow setting the root folder where Typst can find it's external assets. Thank you [jbowtie](https://github.com/jbowtie).

## [v0.1.4] - 2025-04-17

Change the Ubuntu version to 22.04, before it had changed to 24.04 because of the removal of 20.04 from Github actions,
but this caused issues with GLIBC.

## [v0.1.3] - 2025-04-16

Additional functionality added by kevinschweikert, including helpers for tables.

## [v0.1.2] - 2025-03-11

Second release to cope with issues in the checksum file

## [v0.1.1] - 2025-03-11

Updated Typst to verion 0.13 with thanks to a PR from kevinschweikert

## [v0.1.0] - 2024-11-15

First release.

[Unreleased]: https://github.com/Hermanverschooten/typst/compare/v0.3.4...HEAD
[v0.3.4]: https://github.com/Hermanverschooten/typst/compare/v0.3.3...v0.3.4
[v0.3.3]: https://github.com/Hermanverschooten/typst/compare/v0.3.2...v0.3.3
[v0.3.2]: https://github.com/Hermanverschooten/typst/compare/v0.3.1...v0.3.2
[v0.3.1]: https://github.com/Hermanverschooten/typst/compare/v0.3.0...v0.3.1
[v0.3.0]: https://github.com/Hermanverschooten/typst/compare/v0.2.7...v0.3.0
[v0.2.7]: https://github.com/Hermanverschooten/typst/compare/v0.2.6...v0.2.7
[v0.2.6]: https://github.com/Hermanverschooten/typst/compare/v0.2.5...v0.2.6
[v0.2.5]: https://github.com/Hermanverschooten/typst/compare/v0.2.4...v0.2.5
[v0.2.4]: https://github.com/Hermanverschooten/typst/compare/v0.2.3...v0.2.4
[v0.2.3]: https://github.com/Hermanverschooten/typst/compare/v0.2.2...v0.2.3
[v0.2.2]: https://github.com/Hermanverschooten/typst/compare/v0.2.1...v0.2.2
[v0.2.1]: https://github.com/Hermanverschooten/typst/compare/v0.2.0...v0.2.1
[v0.2.0]: https://github.com/Hermanverschooten/typst/releases/tag/v0.2.0
[v0.1.0]: https://github.com/Hermanverschooten/typst/releases/tag/v0.1.0
[v0.1.1]: https://github.com/Hermanverschooten/typst/releases/tag/v0.1.1
[v0.1.2]: https://github.com/Hermanverschooten/typst/releases/tag/v0.1.2
[v0.1.3]: https://github.com/Hermanverschooten/typst/releases/tag/v0.1.3
[v0.1.4]: https://github.com/Hermanverschooten/typst/releases/tag/v0.1.4
[v0.1.5]: https://github.com/Hermanverschooten/typst/releases/tag/v0.1.5
[v0.1.6]: https://github.com/Hermanverschooten/typst/releases/tag/v0.1.6
[v0.1.7]: https://github.com/Hermanverschooten/typst/releases/tag/v0.1.7

