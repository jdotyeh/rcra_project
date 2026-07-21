# =============================================================================
# FILE:     01_download_data.R
# PURPOSE:  Download the EPA Facility Registry Service archive from ECHO and
#           keep the national Program Links file, which cross-references
#           program-system identifiers (including RCRAInfo Handler IDs) to FRS
#           REGISTRY_IDs, and the national Facilities file, which carries each
#           REGISTRY_ID's address and geocoded coordinates.
# INPUTS:   https://echo.epa.gov/files/echodownloads/frs_downloads.zip
# OUTPUTS:  data/frs/FRS_PROGRAM_LINKS.csv, data/frs/FRS_FACILITIES.csv
# AUTHOR:   Jason Ye
# CREATED:  2026-07-17
# UPDATED:  2026-07-21
# =============================================================================

# Download the EPA Facility Registry Service (FRS) archive from ECHO and keep
# FRS_PROGRAM_LINKS.csv and FRS_FACILITIES.csv in data/frs. The archive also
# carries the SIC and NAICS tables, which nothing downstream reads. Program
# Links is what the panel stage reads, because it attaches the FRS REGISTRY_ID
# to each RCRAInfo handler. Facilities is what the Handler master reads, because
# it holds the address and the geocoded LATITUDE83 / LONGITUDE83 pair that the
# master's coordinate override compares against and imports.
# Source: https://echo.epa.gov/tools/data-downloads (FRS download summary)
# Run from the repo root.

# Set the address of the ECHO FRS archive and the folder the kept files live in.
url <- "https://echo.epa.gov/files/echodownloads/frs_downloads.zip"
out_dir <- "data/frs"
keep <- c("FRS_PROGRAM_LINKS.csv", "FRS_FACILITIES.csv")

# Create the output folder if it does not already exist.
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# The archive is about a gigabyte, so raise R's download timeout (60 seconds by
# default) enough to cover a slow connection.
op <- options(timeout = max(3600, getOption("timeout")))
on.exit(options(op), add = TRUE)

# Download the archive in binary mode into the output folder.
zip_path <- file.path(out_dir, "frs_downloads.zip")
download.file(url, zip_path, mode = "wb")

# Extract only the two kept files from the archive.
unzip(zip_path, files = keep, exdir = out_dir)

# Remove the zip so only the kept files remain.
invisible(file.remove(zip_path))

# Print the kept files as confirmation.
cat("Files in", out_dir, ":\n")
print(list.files(out_dir))
