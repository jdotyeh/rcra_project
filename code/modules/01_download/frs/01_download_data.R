# =============================================================================
# FILE:     01_download_data.R
# PURPOSE:  Download the EPA Facility Registry Service archive from ECHO and
#           keep the national Program Links file, which cross-references
#           program-system identifiers (including RCRAInfo Handler IDs) to FRS
#           REGISTRY_IDs.
# INPUTS:   https://echo.epa.gov/files/echodownloads/frs_downloads.zip
# OUTPUTS:  data/frs/FRS_PROGRAM_LINKS.csv
# AUTHOR:   Jason Ye
# CREATED:  2026-07-17
# UPDATED:  2026-07-17
# =============================================================================

# Download the EPA Facility Registry Service (FRS) archive from ECHO and keep
# FRS_PROGRAM_LINKS.csv in data/frs. The archive also carries the FRS facility,
# SIC, and NAICS tables; only the Program Links file is kept, because it is the
# one input the panel stage reads (it attaches the FRS REGISTRY_ID to each
# RCRAInfo handler).
# Source: https://echo.epa.gov/tools/data-downloads (FRS download summary)
# Run from the repo root.

# Set the address of the ECHO FRS archive and the folder the kept file lives in.
url <- "https://echo.epa.gov/files/echodownloads/frs_downloads.zip"
out_dir <- "data/frs"
keep <- "FRS_PROGRAM_LINKS.csv"

# Create the output folder if it does not already exist.
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# The archive is about a gigabyte, so raise R's download timeout (60 seconds by
# default) enough to cover a slow connection.
op <- options(timeout = max(3600, getOption("timeout")))
on.exit(options(op), add = TRUE)

# Download the archive in binary mode into the output folder.
zip_path <- file.path(out_dir, "frs_downloads.zip")
download.file(url, zip_path, mode = "wb")

# Extract only the Program Links file from the archive.
unzip(zip_path, files = keep, exdir = out_dir)

# Remove the zip so only the kept file remains.
invisible(file.remove(zip_path))

# Print the kept file as confirmation.
cat("Files in", out_dir, ":\n")
print(list.files(out_dir))
