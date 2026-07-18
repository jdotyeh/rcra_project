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

# List every package the pipeline relies on. Versions the code was last run
# against are noted in the root README.
required_packages <- c(
  "rvest",      # scrape EPA web pages in the download stage
  "xml2",       # parse XML and HTML returned by EPA pages and APIs
  "jsonlite",   # parse JSON returned by EPA APIs
  "tidyverse",  # reshape and summarize data in the processing stages
  "lubridate",  # parse and compare dates
  "openxlsx2"   # write all Excel workbook output
)

# Identify the required packages that are not installed yet.
missing_packages <- setdiff(required_packages, rownames(installed.packages()))

# Install only the missing packages, so a second run installs nothing.
if (length(missing_packages) > 0) {
  install.packages(missing_packages)
}

# Load every required package, hiding the attachment messages.
invisible(lapply(required_packages, library, character.only = TRUE))

# List the folders the later stages write into. Raw data folders under data/
# are created by each download script as it runs, so only the derived-output
# folders and the data/ root are guaranteed here.
output_dirs <- c(
  "data",
  "output/summary_tables",
  "output/modular_master_files",
  "output/panels"
)

# Create each folder, skipping any that already exist.
for (d in output_dirs) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
}

# Confirm that setup finished.
cat("00_setup complete.\n")
