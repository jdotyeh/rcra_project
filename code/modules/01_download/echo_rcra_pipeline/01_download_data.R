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

url <- "https://echo.epa.gov/files/echodownloads/pipeline_rcra_downloads.zip"
out_dir <- "data/echo_rcra_pipeline"

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# The zip is ~40 MB, so allow up to 10 minutes for slow connections
options(timeout = 600)

zip_path <- file.path(out_dir, "pipeline_rcra_downloads.zip")
download.file(url, zip_path, mode = "wb")

unzip(zip_path, exdir = out_dir)

# Keep only the unzipped files
invisible(file.remove(zip_path))

# Rename PIPELINE_RCRA_* to PIPELINE_*
old_names <- list.files(out_dir, pattern = "^PIPELINE_RCRA_", full.names = TRUE)
new_names <- sub("PIPELINE_RCRA_", "PIPELINE_", old_names, fixed = TRUE)
invisible(file.rename(old_names, new_names))

# Convert the READ_ME table to a markdown file and drop the CSV version
read_me_csv <- file.path(out_dir, "PIPELINE_READ_ME.csv")
read_me <- read.csv(read_me_csv)

header <- paste("|", paste(names(read_me), collapse = " | "), "|")
divider <- paste("|", paste(rep("---", ncol(read_me)), collapse = " | "), "|")
rows <- apply(read_me, 1, function(r) paste("|", paste(r, collapse = " | "), "|"))

writeLines(
  c("# RCRA Pipeline READ ME", "", header, divider, rows),
  file.path(out_dir, "PIPELINE_READ_ME.md")
)
invisible(file.remove(read_me_csv))

cat("Files in", out_dir, ":\n")
print(list.files(out_dir))
