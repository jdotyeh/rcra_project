# Download EPA ECHO RCRAInfo data and unzip it into data/echo_rcra.
# Source: https://echo.epa.gov/tools/data-downloads
# Run from the repo root.

url <- "https://echo.epa.gov/files/echodownloads/rcra_downloads.zip"
out_dir <- "data/echo_rcra"

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# The zip is ~100 MB, so allow up to 30 minutes for slow connections
options(timeout = 1800)

zip_path <- file.path(out_dir, "rcra_downloads.zip")
download.file(url, zip_path, mode = "wb")

unzip(zip_path, exdir = out_dir)

# Keep only the unzipped files
invisible(file.remove(zip_path))

cat("Files in", out_dir, ":\n")
print(list.files(out_dir))
