# =============================================================================
# FILE:     01_download_data.R
# PURPOSE:  Download GHGRP data from two sources: EPA bulk summary and subpart
#           workbooks, and Envirofacts subpart emission tables pulled in chunks.
# INPUTS:   EPA bulk files (https://www.epa.gov/system/files/); Envirofacts REST
#           API (https://data.epa.gov/efservice/);
#           code/modules/01_download/ghgrp/all_ghgrp_tables_years.csv
# OUTPUTS:  data/ghgrp/ (data_summaries/, subpart workbooks,
#           tables/<year>/<TABLE>.csv)
# AUTHOR:   Jason Ye
# CREATED:  2026-07-10
# UPDATED:  2026-07-10
# =============================================================================

# Download EPA Greenhouse Gas Reporting Program (GHGRP) data into data/ghgrp.
#
# Two source types, matching standardizedinventories/stewi/GHGRP.py (Option A):
#
#   1. Bulk files (from https://www.epa.gov/system/files/):
#        - 2023_data_summary_spreadsheets.zip  (unzipped to data/ghgrp/data_summaries)
#        - e_s_cems_bb_cc_ll_full_data_set.xlsx (subparts E, S-CEMS, BB, CC, LL)
#        - l_o_freq_request_data.xlsx           (subparts L, O)
#
#   2. Envirofacts subpart emissions tables (REST API,
#        https://data.epa.gov/efservice/). The set of tables per reporting year
#        is driven by all_ghgrp_tables_years.csv (vendored next to this script
#        from stewi/data/GHGRP/); only rows with PrimaryEmissions == 1 whose
#        REPORTING_YEAR list contains the year are pulled. Each table is fetched
#        in 5,000-row CSV chunks and appended into data/ghgrp/tables/<year>/<TABLE>.csv.
#
# Raw only: bulk workbooks kept as-is; API tables saved as returned (no parsing).
# The query URL format (.../REPORTING_YEAR/=/<year>/ROWS/<a>:<b>/CSV) is EPA's
# and is verified live, but Envirofacts URL formats change periodically.
# Run from the repo root.
#
# Bulk workbooks are saved with RCRAInfo-style names: GHGRP_SUMMARY_<year>.xlsx
# (annual summary spreadsheets), GHGRP_CEMS.xlsx, and GHGRP_FLUORINATED.xlsx.
# The Envirofacts subpart tables keep their EPA table names (already indicative).

library(xml2)

out_dir     <- "data/ghgrp"
tables_root <- file.path(out_dir, "tables")
this_dir    <- "code/modules/01_download/ghgrp"
years       <- 2011:2023

options(timeout = 3600)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ---- 1. Bulk files ----------------------------------------------------------
file_base    <- "https://www.epa.gov/system/files/"
summaries_zip <- "other-files/2024-10/2023_data_summary_spreadsheets.zip"
bulk_xlsx     <- c("GHGRP_CEMS"        = "other-files/2024-10/e_s_cems_bb_cc_ll_full_data_set.xlsx",
                   "GHGRP_FLUORINATED" = "other-files/2024-10/l_o_freq_request_data.xlsx")

cat("[GHGRP] data summary spreadsheets (zip)\n")
zip_path <- file.path(out_dir, basename(summaries_zip))
tryCatch({
  download.file(paste0(file_base, summaries_zip), zip_path, mode = "wb", quiet = TRUE)
  unzip(zip_path, exdir = file.path(out_dir, "data_summaries"))
  for (fp in list.files(file.path(out_dir, "data_summaries"),
                        pattern = "^ghgp_data_\\d{4}\\.xlsx$", full.names = TRUE)) {
    yr <- sub("^ghgp_data_(\\d{4})\\.xlsx$", "\\1", basename(fp))
    file.rename(fp, file.path(dirname(fp), sprintf("GHGRP_SUMMARY_%s.xlsx", yr)))
  }
  invisible(file.remove(zip_path))
}, error = function(e) cat("  failed:", conditionMessage(e), "\n"))

for (nm in names(bulk_xlsx)) {
  cat("[GHGRP]", nm, "\n")
  tryCatch(download.file(paste0(file_base, bulk_xlsx[[nm]]),
                         file.path(out_dir, paste0(nm, ".xlsx")), mode = "wb", quiet = TRUE),
           error = function(e) cat("  failed:", conditionMessage(e), "\n"))
}

# ---- 2. Envirofacts subpart emissions tables --------------------------------
enviro_base <- "https://data.epa.gov/efservice/"

# Append a downloaded chunk CSV onto the table file, keeping the header only from
# the first chunk. Returns number of data rows written.
append_chunk <- function(chunk_path, out_file, first) {
  con <- file(chunk_path, "rt"); lines <- readLines(con, warn = FALSE); close(con)
  if (!length(lines)) return(0L)
  if (first) writeLines(lines, out_file)                 # header + data
  else if (length(lines) > 1) {
    oc <- file(out_file, "at"); writeLines(lines[-1], oc); close(oc)  # data only
  }
  max(length(lines) - 1L, 0L)
}

count_rows <- function(table, year) {
  url <- sprintf("%s%s/REPORTING_YEAR/=/%s/COUNT", enviro_base, table, year)
  n <- tryCatch({
    doc  <- read_xml(url)
    node <- xml_find_first(doc, ".//REQUESTRECORDCOUNT")
    if (inherits(node, "xml_missing")) NA_integer_ else as.integer(xml_text(node))
  }, error = function(e) NA_integer_)
  n
}

tbl <- read.csv(file.path(this_dir, "all_ghgrp_tables_years.csv"),
                stringsAsFactors = FALSE, check.names = FALSE)
tbl <- tbl[!is.na(tbl$PrimaryEmissions) & tbl$PrimaryEmissions == 1, ]

for (year in years) {
  yr <- as.character(year)
  # tables whose REPORTING_YEAR list (e.g. "[2010, 2011, ...]") contains the year
  keep <- grepl(paste0("\\b", yr, "\\b"), tbl$REPORTING_YEAR)
  ytables <- tbl$TABLE[keep]
  if (!length(ytables)) { cat(sprintf("[GHGRP %s] no tables\n", yr)); next }

  ydir <- file.path(tables_root, yr)
  dir.create(ydir, recursive = TRUE, showWarnings = FALSE)
  cat(sprintf("[GHGRP %s] %d subpart emissions tables\n", yr, length(ytables)))

  for (table in ytables) {
    out_file <- file.path(ydir, paste0(table, ".csv"))
    if (file.exists(out_file)) { cat("  exists, skip:", table, "\n"); next }
    n <- count_rows(table, yr)
    if (is.na(n)) { cat("  count failed, skip:", table, "\n"); next }
    if (n == 0)   { cat("  0 rows:", table, "\n"); next }

    cat(sprintf("  %s (rows: %d)\n", table, n))
    starts <- seq(0L, n, by = 5000L)
    first  <- TRUE
    ok     <- TRUE
    for (s in starts) {
      e   <- s + 4999L
      url <- sprintf("%s%s/REPORTING_YEAR/=/%s/ROWS/%d:%d/CSV",
                     enviro_base, table, yr, s, e)
      tmp <- tempfile(fileext = ".csv")
      got <- tryCatch({ download.file(url, tmp, mode = "wb", quiet = TRUE); TRUE },
                      error = function(err) FALSE)
      if (!got) { ok <- FALSE; break }
      append_chunk(tmp, out_file, first); first <- FALSE
      invisible(suppressWarnings(file.remove(tmp)))
    }
    if (!ok && file.exists(out_file)) invisible(file.remove(out_file))  # don't keep partial
  }
}

cat("Done. GHGRP data under", out_dir, "\n")
