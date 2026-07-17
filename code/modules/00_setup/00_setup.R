# =============================================================================
# FILE:     00_setup.R
# PURPOSE:  Prepare the R environment for every stage of the pipeline. Installs
#           any missing packages, loads them, and creates the output folders the
#           later stages write to. master.R sources this first.
# INPUTS:   none
# OUTPUTS:  output/summary_tables/, output/modular_master_files/,
#           output/panels/ and the data/ root (created if absent)
# AUTHOR:   Jason Ye
# CREATED:  2026-07-16
# UPDATED:  2026-07-16
# =============================================================================

# This project was developed and last run under R 4.4.2. The scripts avoid
# newer language features, so a nearby 4.x release is expected to work as well.

# Every package the pipeline relies on. The download stage uses rvest, xml2, and
# jsonlite to read EPA pages and APIs; the processing stages use tidyverse and
# lubridate for reshaping and dates; and all workbook output goes through
# openxlsx2. Versions the code was last run against are noted in the root README.
required_packages <- c(
  "rvest",
  "xml2",
  "jsonlite",
  "tidyverse",
  "lubridate",
  "openxlsx2"
)

# Install only what is not already present, then load everything. Running the
# whole pipeline a second time therefore installs nothing.
missing_packages <- setdiff(required_packages, rownames(installed.packages()))
if (length(missing_packages) > 0) {
  install.packages(missing_packages)
}

invisible(lapply(required_packages, library, character.only = TRUE))

# Folders the later stages write into. Raw data folders under data/ are created
# by each download script as it runs, so only the derived-output folders and the
# data/ root are guaranteed here. recursive = TRUE makes each call idempotent.
output_dirs <- c(
  "data",
  "output/summary_tables",
  "output/modular_master_files",
  "output/panels"
)

for (d in output_dirs) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
}

cat("Setup complete. Packages loaded and output folders ready.\n")
