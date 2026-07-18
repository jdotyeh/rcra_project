# =============================================================================
# FILE:     01_download_data.R
# PURPOSE:  Download eGRID plant-level workbooks, one xlsx per available year,
#           extracting the 2014 and 2016 books from EPA's historical archive zip.
# INPUTS:   EPA eGRID page and historical-archive zip (per-year URLs in-script)
# OUTPUTS:  data/egrid/EGRID_PLANT_<year>.xlsx
# AUTHOR:   Jason Ye
# CREATED:  2026-07-10
# UPDATED:  2026-07-10
# =============================================================================

# Download EPA Emissions & Generation Resource Integrated Database (eGRID) data
# workbooks into data/egrid, one .xlsx per available year.
#
# Most years are a single .xlsx served directly. The 2014 and 2016 workbooks are
# only distributed inside the historical archive
# (egrid2018_historical_files_since_1996.zip), so that zip is downloaded once and
# the two workbooks are extracted from it. Raw only: the .xlsx workbooks are
# saved as-is; no sheet parsing.
#
# Port of the download step in standardizedinventories/stewi/egrid.py (Option A),
# which reads per-year file_name / download_url from stewi/config.yaml.
# Source page: https://www.epa.gov/egrid/emissions-generation-resource-integrated-database-egrid
# Run from the repo root.
#
# Workbooks are saved with RCRAInfo-style names: EGRID_PLANT_<year>.xlsx.

# Set the output folder and create it if it does not already exist.
out_dir <- "data/egrid"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Allow up to 30 minutes; the historical archive is ~160 MB.
options(timeout = 1800)

# Point to the historical-archive zip that holds the 2014 and 2016 workbooks.
hist_zip <- paste0("https://www.epa.gov/sites/production/files/2020-01/",
                   "egrid2018_historical_files_since_1996.zip")

# Map each year to its workbook file name and how to fetch it. `zip = TRUE` means
# the file is extracted from `hist_zip`; otherwise `url` is a direct .xlsx download.
egrid <- list(
  "2014" = list(file = "eGRID2014_Data_v2.xlsx", zip = TRUE),
  "2016" = list(file = "egrid2016_data.xlsx",    zip = TRUE),
  "2018" = list(file = "eGRID2018_Data_v2.xlsx",
                url  = "https://www.epa.gov/sites/production/files/2020-03/egrid2018_data_v2.xlsx"),
  "2019" = list(file = "eGRID2019_data.xlsx",
                url  = "https://www.epa.gov/sites/production/files/2021-02/egrid2019_data.xlsx"),
  "2020" = list(file = "eGRID2020_Data_v2.xlsx",
                url  = "https://www.epa.gov/system/files/documents/2022-09/eGRID2020_Data_v2.xlsx"),
  "2021" = list(file = "eGRID2021_data.xlsx",
                url  = "https://www.epa.gov/system/files/documents/2023-01/eGRID2021_data.xlsx"),
  "2022" = list(file = "egrid2022_data.xlsx",
                url  = "https://www.epa.gov/system/files/documents/2024-01/egrid2022_data.xlsx"),
  "2023" = list(file = "egrid2023_data_rev2.xlsx",
                url  = "https://www.epa.gov/system/files/documents/2025-06/egrid2023_data_rev2.xlsx")
)

# Download the years served as direct .xlsx files.
for (year in names(egrid)) {
  spec <- egrid[[year]]
  # Skip the years that live inside the historical archive.
  if (isTRUE(spec$zip)) next
  # Build the destination path with the RCRAInfo-style name.
  dest <- file.path(out_dir, sprintf("EGRID_PLANT_%s.xlsx", year))
  # Log the year and URL being fetched.
  cat(sprintf("[eGRID %s] %s\n", year, spec$url))
  # Download the workbook, reporting a failure without stopping the loop.
  tryCatch(download.file(spec$url, dest, mode = "wb", quiet = TRUE),
           error = function(e) cat("  download failed:", conditionMessage(e), "\n"))
}

# Extract the workbooks that live inside the historical archive (2014, 2016).
zip_years <- names(egrid)[vapply(egrid, function(s) isTRUE(s$zip), logical(1))]
if (length(zip_years)) {
  # Download the archive once into a temporary zip.
  tmp <- file.path(out_dir, "egrid_historical.zip")
  cat(sprintf("[eGRID %s] %s\n", paste(zip_years, collapse = "/"), hist_zip))
  tryCatch({
    download.file(hist_zip, tmp, mode = "wb", quiet = TRUE)
    # List the archive contents.
    inside <- unzip(tmp, list = TRUE)$Name
    for (y in zip_years) {
      # Locate the year's workbook inside the archive.
      f   <- egrid[[y]]$file
      hit <- inside[basename(inside) == f]
      # Report a missing workbook and move on.
      if (!length(hit)) { cat("  not found in archive:", f, "\n"); next }
      # Extract the workbook and rename it to the RCRAInfo-style name.
      unzip(tmp, files = hit[1], exdir = out_dir, junkpaths = TRUE)
      file.rename(file.path(out_dir, basename(hit[1])),
                  file.path(out_dir, sprintf("EGRID_PLANT_%s.xlsx", y)))
    }
    # Remove the archive after extraction.
    invisible(file.remove(tmp))
  }, error = function(e) cat("  archive step failed:", conditionMessage(e), "\n"))
}

# Print the final files as confirmation.
cat("Done. Files in", out_dir, ":\n"); print(list.files(out_dir))
