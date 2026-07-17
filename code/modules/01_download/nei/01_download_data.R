# =============================================================================
# FILE:     01_download_data.R
# PURPOSE:  Download NEI point-source emission extracts as EPA-staged Parquet
#           files, one folder per reporting year, kept raw.
# INPUTS:   EPA ORD Data Commons S3 bucket (StEWI NEI Data Files; URLs in-script)
# OUTPUTS:  data/nei/<year>/NEI_POINT_<i>.parquet
# AUTHOR:   Jason Ye
# CREATED:  2026-07-10
# UPDATED:  2026-07-10
# =============================================================================

# Download EPA National Emissions Inventory (NEI) point-source data into data/nei,
# one folder per reporting year.
#
# StEWI does not pull NEI point data from EIS directly; it reads EPA-staged
# extracts (Apache Parquet) from the ORD Data Commons S3 bucket. The file names
# per year are fixed in standardizedinventories/stewi/config.yaml and resolve
# 1:1 to keys under the "stewi/NEI Data Files/" prefix, so each parquet is
# downloaded by name. Raw only: parquet files are saved as-is.
#
# Port of the download step in standardizedinventories/stewi/NEI.py (Option A,
# via esupy download_from_remote). NEI is triennial (2011, 2014, 2017, 2020)
# with interim years in between; all years present in config are listed here.
# Bucket: https://dmap-data-commons-ord.s3.amazonaws.com/stewi/NEI Data Files/
# Run from the repo root.
#
# Files are saved with RCRAInfo-style names: NEI_POINT_0.parquet, NEI_POINT_1,
# ... per year (index follows the region-group order for that year).

out_root <- "data/nei"
base_url <- "https://dmap-data-commons-ord.s3.amazonaws.com/stewi/NEI%20Data%20Files/"

# Each parquet is large; allow up to 1 hour per file.
options(timeout = 3600)

# year -> parquet file name(s) (from config.yaml). Multiple files per year are
# EPA region groupings that together make up the national point-source dataset.
nei <- list(
  "2011" = c("nei_2011_regions_1_thru_5.parquet",
             "nei_2011_regions_6_thru_10_and_other.parquet"),
  "2012" = c("sppd_rtr_17208.parquet", "sppd_rtr_17209.parquet"),
  "2013" = c("sppd_rtr_17198.parquet", "sppd_rtr_17207.parquet"),
  "2014" = c("nei_2014_regions_1_thru_5.parquet",
             "nei_2014_regions_6_thru_10_and_other.parquet"),
  "2015" = c("sppd_rtr_17021.parquet", "sppd_rtr_17197.parquet"),
  "2016" = c("sppd_rtr_16974.parquet", "sppd_rtr_16998.parquet"),
  "2017" = c("sppd_rtr_16940.parquet", "sppd_rtr_16958.parquet"),
  "2018" = c("sppd_rtr_16938.parquet", "sppd_rtr_16939.parquet"),
  "2019" = c("sppd_rtr_24593.parquet", "sppd_rtr_24671.parquet",
             "sppd_rtr_24672.parquet", "sppd_rtr_24673.parquet"),
  "2020" = c("sppd_rtr_24240.parquet", "sppd_rtr_24506.parquet",
             "sppd_rtr_24507.parquet", "sppd_rtr_24592.parquet"),
  "2021" = c("sppd_rtr_31440.parquet", "sppd_rtr_31463.parquet",
             "sppd_rtr_31510.parquet", "sppd_rtr_31511.parquet"),
  "2022" = c("sppd_rtr_31281.parquet", "sppd_rtr_31284.parquet",
             "sppd_rtr_31302.parquet", "sppd_rtr_31303.parquet")
)

for (year in names(nei)) {
  out_dir <- file.path(out_root, year)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  files <- nei[[year]]
  for (i in seq_along(files)) {
    f    <- files[i]
    dest <- file.path(out_dir, sprintf("NEI_POINT_%d.parquet", i - 1L))
    if (file.exists(dest)) { cat("  exists, skip:", basename(dest), "\n"); next }
    url <- paste0(base_url, utils::URLencode(f))
    cat(sprintf("[NEI %s] %s\n", year, basename(dest)))
    tryCatch(download.file(url, dest, mode = "wb", quiet = TRUE),
             error = function(e) cat("  download failed:", conditionMessage(e), "\n"))
  }
}

cat("Done. Years in", out_root, ":", paste(list.files(out_root), collapse = ", "), "\n")
