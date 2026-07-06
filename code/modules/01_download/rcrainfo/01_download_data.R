# Download all RCRAInfo CSV exports from the EPA Hazardous Waste Information
# Platform (HWIP) and store them under data/rcrainfo, one folder per module
# (lower case): br, ca, ce, em, fa, hd, pm, wt.
#
# The downloads page lists three sections (summary, module, and by-year
# files), all served by the HWIP API. Zip files are downloaded, unzipped,
# and removed. Tables with more than one million records are split into
# numbered part files (TABLE_0.csv, TABLE_1.csv, ...); the parts are
# appended into a single TABLE.csv. Reporting files are stored in the
# folder of their module: CE_REPORTING.zip -> ce.
#
# Source: https://rcrapublic.epa.gov/rcra-hwip/data-access/csv-downloads
# Run from the repo root. Downloads are ~4 GB total, so this takes a while.

library(jsonlite)

api_base <- "https://rcrapublic.epa.gov/rcra-hwip/api/"
out_root <- "data/rcrainfo"

# Some zips are ~2 GB, so allow up to 3 hours per file
options(timeout = 10800)

# Append split CSVs into one file. Every part has its own header row,
# so keep the header from the first part only. Parts are streamed in
# chunks to keep memory use low (some parts are several hundred MB).
append_parts <- function(parts, out_file) {
  parts <- parts[order(as.numeric(sub(".*_(\\d+)\\.csv$", "\\1", parts)))]
  file.copy(parts[1], out_file, overwrite = TRUE)
  out <- file(out_file, "at")
  for (p in parts[-1]) {
    con <- file(p, "rt")
    readLines(con, n = 1)
    while (length(chunk <- readLines(con, n = 100000)) > 0) writeLines(chunk, out)
    close(con)
  }
  close(out)
  invisible(file.remove(parts))
}

# Unzip a downloaded zip, unzip any nested table zips (module files contain
# one zip per table), and append the split CSVs into one CSV per table
process_zip <- function(zip_path, out_dir) {
  extracted <- unzip(zip_path, exdir = out_dir)
  invisible(file.remove(zip_path))

  nested <- extracted[grepl("\\.zip$", extracted)]
  for (z in nested) extracted <- c(extracted, unzip(z, exdir = out_dir))
  invisible(file.remove(nested))
  extracted <- setdiff(extracted, nested)

  csvs <- extracted[grepl("_\\d+\\.csv$", extracted)]
  bases <- sub("_\\d+\\.csv$", "", csvs)
  for (b in unique(bases)) append_parts(csvs[bases == b], paste0(b, ".csv"))
}

# The three sections of the downloads page
sections <- c("export/summaries", "export/modules", "export/tables")
files <- do.call(rbind, lapply(sections, function(s) fromJSON(paste0(api_base, s))))

for (i in seq_len(nrow(files))) {
  file_name <- files$fileName[i]

  # Files belong to the module named by their prefix: CE_REPORTING.zip -> ce
  module <- tolower(strsplit(file_name, "[_.]")[[1]][1])
  out_dir <- file.path(out_root, module)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  cat(sprintf("[%d/%d] %s -> %s\n", i, nrow(files), file_name, out_dir))
  zip_path <- file.path(out_dir, file_name)
  download.file(files$url[i], zip_path, mode = "wb", quiet = TRUE)
  process_zip(zip_path, out_dir)
}

cat("Done. Files per module:\n")
for (m in list.files(out_root)) {
  cat(m, ":", paste(list.files(file.path(out_root, m)), collapse = ", "), "\n")
}
