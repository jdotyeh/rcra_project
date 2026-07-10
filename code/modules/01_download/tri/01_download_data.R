# Download EPA Toxics Release Inventory (TRI) Basic Plus national data files and
# unzip them into data/tri, one folder per reporting year.
#
# TRI publishes one national zip per calendar year (us_<year>.zip) holding the
# tab-delimited Basic Plus files: US_1a_<year>.txt (Releases and Other Waste
# Management), US_3a_<year>.txt (Off-Site Transfers), and the other file types
# (1b, 2a, 2b, 3b, 3c, ...). This script keeps the whole archive per year; it
# does not parse or subset the .txt files (that is a later, cleaning step).
#
# The old StEWI location (https://www3.epa.gov/tri/current2/US_<year>.zip) is
# deprecated. EPA now serves the zips under dated folders,
# https://www.epa.gov/system/files/other-files/<YYYY-MM>/us_<year>.zip, and the
# folder differs by year, so the per-year URLs are listed explicitly below
# (verified live 2026-07-08: 2012-2024 under 2025-11, 2011 under 2025-09). When
# EPA republishes under a new dated folder, update these URLs -- the current
# links are on the TRI Basic Plus source page.
# Source page: https://www.epa.gov/toxics-release-inventory-tri-program/tri-basic-plus-data-files-calendar-years-1987-present
# Run from the repo root.
#
# Extracted files are renamed to RCRAInfo-style names (UPPERCASE dataset prefix +
# one-word content tag): TRI_RELEASES, TRI_REDUCTION, TRI_PROJECTIONS,
# TRI_TREATMENT, TRI_TRANSFERS, TRI_POTW, TRI_PARENT, TRI_FACILITY,
# TRI_SUBMISSION, and TRI_DEPRECATED (file 3b, not produced after 2010).

years    <- 2011:2024
out_root <- "data/tri"

# TRI Basic Plus file-type code -> content tag.
tri_names <- c("1a" = "RELEASES", "1b" = "REDUCTION", "2a" = "PROJECTIONS",
               "2b" = "TREATMENT", "3a" = "TRANSFERS", "3b" = "DEPRECATED",
               "3c" = "POTW", "4" = "PARENT", "5" = "FACILITY", "6" = "SUBMISSION")

# year -> zip URL (dated-folder path; see note above).
base    <- "https://www.epa.gov/system/files/other-files"
tri_zip <- setNames(sprintf("%s/2025-11/us_%d.zip", base, 2012:2024),
                    as.character(2012:2024))
tri_zip["2011"] <- sprintf("%s/2025-09/us_2011.zip", base)

# The national zips run from ~7 MB (older years) to ~65 MB; allow 30 minutes.
options(timeout = 1800)

for (year in years) {
  url <- tri_zip[[as.character(year)]]
  if (is.null(url) || is.na(url)) {
    cat(sprintf("[TRI %d] no URL on file; skipping (add it to tri_zip)\n", year))
    next
  }
  out_dir <- file.path(out_root, year)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  zip_path <- file.path(out_dir, sprintf("us_%d.zip", year))
  cat(sprintf("[TRI %d] %s\n", year, url))
  ok <- tryCatch({ download.file(url, zip_path, mode = "wb", quiet = TRUE); TRUE },
                 error = function(e) { cat("  download failed:", conditionMessage(e), "\n"); FALSE })
  if (!ok) next

  unzip(zip_path, exdir = out_dir)
  invisible(file.remove(zip_path))
  for (code in names(tri_names)) {
    src <- file.path(out_dir, sprintf("US_%s_%d.txt", code, year))
    if (file.exists(src))
      file.rename(src, file.path(out_dir, sprintf("TRI_%s.txt", tri_names[[code]])))
  }
  cat("  ->", paste(list.files(out_dir), collapse = ", "), "\n")
}

cat("Done. Years in", out_root, ":", paste(list.files(out_root), collapse = ", "), "\n")
