# =============================================================================
# FILE:     01_download_data.R
# PURPOSE:  Download the EPA ECHO RCRAInfo dataset archive and unzip it, keeping
#           the CSV tables for hazardous-waste sites.
# INPUTS:   https://echo.epa.gov/files/echodownloads/rcra_downloads.zip
# OUTPUTS:  data/echo_rcra/*.csv
# AUTHOR:   Jason Ye
# CREATED:  2026-07-06
# UPDATED:  2026-07-06
# =============================================================================

# Download EPA ECHO RCRAInfo data and unzip it into data/echo_rcra.
# Source: https://echo.epa.gov/tools/data-downloads
# Run from the repo root.

# Set the address of the ECHO RCRAInfo archive and the folder it unzips into.
url <- "https://echo.epa.gov/files/echodownloads/rcra_downloads.zip"
out_dir <- "data/echo_rcra"

# Create the output folder if it does not already exist.
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Download the archive in binary mode into the output folder.
zip_path <- file.path(out_dir, "rcra_downloads.zip")
download.file(url, zip_path, mode = "wb")

# Extract every file from the archive.
unzip(zip_path, exdir = out_dir)

# Remove the zip so only the unzipped files remain.
invisible(file.remove(zip_path))

# Print the extracted files as confirmation.
cat("Files in", out_dir, ":\n")
print(list.files(out_dir))
