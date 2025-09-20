use std::collections::HashMap;
// use std::fs;
use std::path::PathBuf;
use std::sync::{Arc, Mutex};

use typst::diag::{eco_format, FileError, FileResult, PackageError, PackageResult};
use typst::foundations::{Bytes, Datetime};
use typst::syntax::package::PackageSpec;
use typst::syntax::{FileId, Source};
use typst::text::{Font, FontBook};
use typst::utils::LazyHash;
use typst::Library;
use typst_kit::fonts::{FontSlot, Fonts};
use typst_pdf::PdfOptions;

/// Main interface that determines the environment for Typst.
pub struct TypstNifWorld {
    /// Root path to which files will be resolved.
    root: PathBuf,

    /// The content of a source.
    source: Source,

    /// The standard library.
    library: LazyHash<Library>,

    /// Metadata about all known fonts.
    book: LazyHash<FontBook>,

    /// Metadata about all known fonts.
    fonts: Vec<FontSlot>,

    /// Map of all known files.
    files: Arc<Mutex<HashMap<FileId, FileEntry>>>,

    /// Cache directory (e.g. where packages are downloaded to).
    cache_directory: PathBuf,

    /// http agent to download packages.
    http: ureq::Agent,

    /// Datetime.
    time: time::OffsetDateTime,
}

impl TypstNifWorld {
    pub fn new(root: String, source: String, extra_fonts: Vec<String>) -> Self {
        let root = PathBuf::from(root);
        // let fonts = fonts(&root);
        let fonts = Fonts::searcher()
            .include_system_fonts(true)
            .search_with(extra_fonts);

        Self {
            library: LazyHash::new(Library::default()),
            book: LazyHash::new(fonts.book),
            root,
            fonts: fonts.fonts,
            source: Source::detached(source),
            time: time::OffsetDateTime::now_utc(),
            cache_directory: std::env::var_os("CACHE_DIRECTORY")
                .map(|os_path| os_path.into())
                .unwrap_or(std::env::temp_dir()),
            http: ureq::Agent::new(),
            files: Arc::new(Mutex::new(HashMap::new())),
        }
    }
}

/// A File that will be stored in the HashMap.
#[derive(Clone, Debug)]
struct FileEntry {
    bytes: Bytes,
    source: Option<Source>,
}

impl FileEntry {
    fn new(bytes: Vec<u8>, source: Option<Source>) -> Self {
        Self {
            bytes: Bytes::new(bytes),
            source,
        }
    }

    fn source(&mut self, id: FileId) -> FileResult<Source> {
        let source = if let Some(source) = &self.source {
            source
        } else {
            let contents = std::str::from_utf8(&self.bytes).map_err(|_| FileError::InvalidUtf8)?;
            let contents = contents.trim_start_matches('\u{feff}');
            let source = Source::new(id, contents.into());
            self.source.insert(source)
        };
        Ok(source.clone())
    }
}

impl TypstNifWorld {
    /// Helper to handle file requests.
    ///
    /// Requests will be either in packages or a local file.
    fn file(&self, id: FileId) -> FileResult<FileEntry> {
        let mut files = self.files.lock().map_err(|_| FileError::AccessDenied)?;
        if let Some(entry) = files.get(&id) {
            return Ok(entry.clone());
        }
        let path = if let Some(package) = id.package() {
            // Fetching file from package
            let package_dir = self.download_package(package)?;
            id.vpath().resolve(&package_dir)
        } else {
            // Fetching file from disk
            id.vpath().resolve(&self.root)
        }
        .ok_or(FileError::AccessDenied)?;

        let content = std::fs::read(&path).map_err(|error| FileError::from_io(error, &path))?;
        Ok(files
            .entry(id)
            .or_insert(FileEntry::new(content, None))
            .clone())
    }

    /// Downloads the package and returns the system path of the unpacked package.
    fn download_package(&self, package: &PackageSpec) -> PackageResult<PathBuf> {
        let package_subdir = format!("{}/{}/{}", package.namespace, package.name, package.version);
        let path = self.cache_directory.join(package_subdir);

        if path.exists() {
            return Ok(path);
        }

        eprintln!("downloading {package}");
        let url = format!(
            "https://packages.typst.org/{}/{}-{}.tar.gz",
            package.namespace, package.name, package.version,
        );

        let response = retry(|| {
            let response = self
                .http
                .get(&url)
                .call()
                .map_err(|error| eco_format!("{error}"))?;

            let status = response.status();
            if !http_successful(status) {
                return Err(eco_format!(
                    "response returned unsuccessful status code {status}",
                ));
            }

            Ok(response)
        })
        .map_err(|error| PackageError::NetworkFailed(Some(error)))?;

        let mut compressed_archive = Vec::new();
        response
            .into_reader()
            .read_to_end(&mut compressed_archive)
            .map_err(|error| PackageError::NetworkFailed(Some(eco_format!("{error}"))))?;
        let raw_archive = zune_inflate::DeflateDecoder::new(&compressed_archive)
            .decode_gzip()
            .map_err(|error| PackageError::MalformedArchive(Some(eco_format!("{error}"))))?;
        let mut archive = tar::Archive::new(raw_archive.as_slice());
        archive.unpack(&path).map_err(|error| {
            _ = std::fs::remove_dir_all(&path);
            PackageError::MalformedArchive(Some(eco_format!("{error}")))
        })?;

        Ok(path)
    }
}

/// This is the interface we have to implement such that `typst` can compile it.
///
/// I have tried to keep it as minimal as possible
impl typst::World for TypstNifWorld {
    /// Standard library.
    fn library(&self) -> &LazyHash<Library> {
        &self.library
    }

    /// Metadata about all known Books.
    fn book(&self) -> &LazyHash<FontBook> {
        &self.book
    }

    /// Accessing the main source file.
    fn main(&self) -> FileId {
        self.source.id()
    }

    /// Accessing a specified source file (based on `FileId`).
    fn source(&self, id: FileId) -> FileResult<Source> {
        if id == self.source.id() {
            Ok(self.source.clone())
        } else {
            self.file(id)?.source(id)
        }
    }

    /// Accessing a specified file (non-file).
    fn file(&self, id: FileId) -> FileResult<Bytes> {
        self.file(id).map(|file| file.bytes.clone())
    }

    /// Accessing a specified font per index of font book.
    fn font(&self, id: usize) -> Option<Font> {
        self.fonts[id].get()
    }

    /// Get the current date.
    ///
    /// Optionally, an offset in hours is given.
    fn today(&self, offset: Option<i64>) -> Option<Datetime> {
        let offset = offset.unwrap_or(0);
        let offset = time::UtcOffset::from_hms(offset.try_into().ok()?, 0, 0).ok()?;
        let time = self.time.checked_to_offset(offset)?;
        Some(Datetime::Date(time.date()))
    }
}

fn retry<T, E>(mut f: impl FnMut() -> Result<T, E>) -> Result<T, E> {
    if let Ok(ok) = f() {
        Ok(ok)
    } else {
        f()
    }
}

fn http_successful(status: u16) -> bool {
    // 2XX
    status / 100 == 2
}

#[rustler::nif]
fn compile<'a>(markup: String, root_dir: String, extra_fonts: Vec<String>) -> Result<String, String> {
    let world = TypstNifWorld::new(root_dir, markup, extra_fonts);

    match typst::compile(&world).output {
        Ok(document) => {
            match typst_pdf::pdf(&document, &PdfOptions::default()) {
                Ok(pdf_bytes) => {
                    // the resulting string is not an utf-8 encoded string, but this is exactly what we
                    // want as we are passing a binary back to elixir
                    unsafe {
                        return Ok(String::from_utf8_unchecked(pdf_bytes));
                    }
                }
                Err(e) => {
                    let error_string = format!("{:#?}", e);
                    return Err(error_string);
                }
            };
        }
        Err(errors) => {
            let mut error_messages = Vec::new();

            for error in errors {
                let span = error.span;
                let source = &world.source;

                let mut error_msg = format!("Error: {}", error.message);

                // Try to get source location information
                if !span.is_detached() && span.id() == Some(source.id()) {
                    if let Some(range) = source.range(span) {
                        let line = source.byte_to_line(range.start).unwrap_or(0) + 1;
                        let column = source.byte_to_column(range.start).unwrap_or(0) + 1;

                        error_msg = format!("[line {}:{}] {}", line, column, error.message);

                        // Try to get the actual source line for context
                        if let Some(line_range) = source.line_to_range(line - 1) {
                            let source_line = &source.text()[line_range];
                            let trimmed_line = source_line.trim_end();

                            // Calculate the position of the error marker
                            let leading_spaces = source_line.len() - source_line.trim_start().len();
                            let marker_pos = column.saturating_sub(1).saturating_sub(leading_spaces);

                            error_msg = format!(
                                "{}\n  Source: {}\n         {}{}",
                                error_msg,
                                trimmed_line.trim(),
                                " ".repeat(marker_pos),
                                "^"
                            );
                        }
                    }
                }

                // Add hints if any
                for hint in &error.hints {
                    error_msg = format!("{}\n  Hint: {}", error_msg, hint);
                }

                error_messages.push(error_msg);
            }

            return Err(error_messages.join("\n\n"));
        }
    };
}

rustler::init!("Elixir.Typst.NIF");
