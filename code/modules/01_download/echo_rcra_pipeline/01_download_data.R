# =============================================================================
# FILE:     01_download_data.R
# PURPOSE:  Download the EPA ECHO RCRA pipeline dataset archive, unzip it, rename
#           the tables to PIPELINE_* names, and convert the bundled read me.
# INPUTS:   https://echo.epa.gov/files/echodownloads/pipeline_rcra_downloads.zip
# OUTPUTS:  data/echo_rcra_pipeline/PIPELINE_*.csv,
#           data/echo_rcra_pipeline/PIPELINE_READ_ME.md
# AUTHOR:   Jason Ye
# CREATED:  2026-07-06
# UPDATED:  2026-07-06
# =============================================================================

# Download EPA ECHO RCRA pipeline data and unzip it into data/echo_rcra_pipeline.
# Source: https://echo.epa.gov/tools/data-downloads
# Run from the repo root.

# Set the address of the ECHO RCRA pipeline archive and the folder it unzips into.
url <- "https://echo.epa.gov/files/echodownloads/pipeline_rcra_downloads.zip"
out_dir <- "data/echo_rcra_pipeline"

# Create the output folder if it does not already exist.
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Download the archive in binary mode into the output folder.
zip_path <- file.path(out_dir, "pipeline_rcra_downloads.zip")
download.file(url, zip_path, mode = "wb")

# Extract every file from the archive.
unzip(zip_path, exdir = out_dir)

# Remove the zip so only the unzipped files remain.
invisible(file.remove(zip_path))

# Rename PIPELINE_RCRA_* files to PIPELINE_*.
old_names <- list.files(out_dir, pattern = "^PIPELINE_RCRA_", full.names = TRUE)  # find files with the long prefix
new_names <- sub("PIPELINE_RCRA_", "PIPELINE_", old_names, fixed = TRUE)          # build the shortened names
invisible(file.rename(old_names, new_names))                                      # apply the renames

# Read the bundled README table from its CSV.
read_me_csv <- file.path(out_dir, "PIPELINE_READ_ME.csv")
read_me <- read.csv(read_me_csv)

# Build the header row, divider row, and data rows.
header <- paste("|", paste(names(read_me), collapse = " | "), "|")
divider <- paste("|", paste(rep("---", ncol(read_me)), collapse = " | "), "|")
rows <- apply(read_me, 1, function(r) paste("|", paste(r, collapse = " | "), "|"))

# Write README.md, then drop the CSV version.
writeLines(
  c("# RCRA Pipeline READ ME", "", header, divider, rows),
  file.path(out_dir, "PIPELINE_READ_ME.md")
)
invisible(file.remove(read_me_csv))

# Print the final files as confirmation.
cat("Files in", out_dir, ":\n")
print(list.files(out_dir))
