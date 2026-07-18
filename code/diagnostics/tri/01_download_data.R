# =============================================================================
# FILE:     01_download_data.R
# PURPOSE:  Download TRI Basic Plus national archives and unzip them, one folder
#           per reporting year. Files are kept raw and renamed by content tag.
# INPUTS:   EPA TRI Basic Plus per-year zips
#           (https://www.epa.gov/system/files/other-files/<YYYY-MM>/us_<year>.zip)
# OUTPUTS:  data/tri/<year>/TRI_*.txt
# AUTHOR:   Jason Ye
# CREATED:  2026-07-10
# UPDATED:  2026-07-10
# =============================================================================

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

# Set the reporting years and the output root.
years    <- 2011:2024
out_root <- "data/tri"

# Map each TRI Basic Plus file-type code to its content tag.
tri_names <- c("1a" = "RELEASES", "1b" = "REDUCTION", "2a" = "PROJECTIONS",
               "2b" = "TREATMENT", "3a" = "TRANSFERS", "3b" = "DEPRECATED",
               "3c" = "POTW", "4" = "PARENT", "5" = "FACILITY", "6" = "SUBMISSION")

# Map each year to its zip URL (dated-folder path; see note above).
base    <- "https://www.epa.gov/system/files/other-files"
tri_zip <- setNames(sprintf("%s/2025-11/us_%d.zip", base, 2012:2024),
                    as.character(2012:2024))
tri_zip["2011"] <- sprintf("%s/2025-09/us_2011.zip", base)

# Allow 30 minutes; the national zips run from ~7 MB (older years) to ~65 MB.
options(timeout = 1800)

# Download and unpack each year.
for (year in years) {
  # Look up the year's URL; skip years without one.
  url <- tri_zip[[as.character(year)]]
  if (is.null(url) || is.na(url)) {
    cat(sprintf("[TRI %d] no URL on file; skipping (add it to tri_zip)\n", year))
    next
  }
  # Create the year folder.
  out_dir <- file.path(out_root, year)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  # Download the zip, reporting a failure without stopping the loop.
  zip_path <- file.path(out_dir, sprintf("us_%d.zip", year))
  cat(sprintf("[TRI %d] %s\n", year, url))
  ok <- tryCatch({ download.file(url, zip_path, mode = "wb", quiet = TRUE); TRUE },
                 error = function(e) { cat("  download failed:", conditionMessage(e), "\n"); FALSE })
  if (!ok) next

  # Extract the archive and remove the zip.
  unzip(zip_path, exdir = out_dir)
  invisible(file.remove(zip_path))
  # Rename each US_<code>_<year>.txt to its TRI_<TAG>.txt name.
  for (code in names(tri_names)) {
    src <- file.path(out_dir, sprintf("US_%s_%d.txt", code, year))
    if (file.exists(src))
      file.rename(src, file.path(out_dir, sprintf("TRI_%s.txt", tri_names[[code]])))
  }
  # Log the extracted files.
  cat("  ->", paste(list.files(out_dir), collapse = ", "), "\n")
}

# Print the completed years as confirmation.
cat("Done. Years in", out_root, ":", paste(list.files(out_root), collapse = ", "), "\n")
