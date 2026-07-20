# =============================================================================
# 02_exact_duplicates.R  —  Exact-duplicate inspection engine
# -----------------------------------------------------------------------------
# Inspects whether a data file of interest contains EXACT duplicate rows.
#
# HOW TO USE:
#   Change ONLY the `target` value below, then run the whole script.
#   Everything else is automatic.
#
#   `target` is matched against the START of the CSV file name, so one value
#   can also cover several files at once. Examples:
#       target <- "HD_REPORTING"        # -> HD_REPORTING.csv
#       target <- "CE_REPORTING"        # -> CE_REPORTING.csv
#       target <- "CA_EVENT"            # -> CA_EVENT.csv
#       target <- "PM_EVENT"            # -> PM_EVENT.csv, PM_EVENT_UNIT_DETAIL.csv
#       target <- "FA_COST_ESTIMATE"    # -> FA_COST_ESTIMATE.csv
#       target <- "WT_NOTICES_EXPORTS"  # -> WT_NOTICES_EXPORTS.csv
#       target <- "BR_REPORTING"        # -> every Biennial Report cycle file
#
# WHAT IT REPORTS:
#   * Per-file: rows, exact-duplicate rows, and a few example duplicates.
#   * Combined (when several matched files share one schema): duplicates that
#     span the whole matched set, so a row repeated across files is caught.
# =============================================================================

# ----------------------------- CHANGE THIS ONLY -----------------------------
target <- "BR_REPORTING_2003"
# ----------------------------------------------------------------------------

suppressPackageStartupMessages(library(data.table))

# Root that holds all the RCRAInfo files. Adjust once if you move the script;
# the recursive search handles every sub-folder underneath it.
data_root <- "data/rcrainfo"

# --- Locate every CSV whose file name begins with `target` -------------------
all_csv <- list.files(data_root, pattern = "\\.csv$", recursive = TRUE,
                       full.names = TRUE, ignore.case = TRUE)
files <- all_csv[startsWith(basename(all_csv), target)]

if (length(files) == 0L) {
  stop(sprintf("No CSV files under '%s' start with '%s'.\nAvailable example names:\n  %s",
               data_root, target,
               paste(head(sort(basename(all_csv)), 20L), collapse = "\n  ")))
}

cat("=========================================================\n")
cat("Exact-duplicate check for target:", target, "\n")
cat("Matched", length(files), "file(s):\n")
cat(paste0("  - ", files, collapse = "\n"), "\n")
cat("=========================================================\n\n")

# Read every column as character so "exact" means byte-for-byte identical
read_one <- function(f) {
  fread(f, colClasses = "character", showProgress = FALSE,
        na.strings = NULL, keepLeadingZeros = TRUE)
}

# --- Per-file inspection -----------------------------------------------------
parts <- vector("list", length(files))
for (i in seq_along(files)) {
  f  <- files[i]
  dt <- read_one(f)
  dup <- duplicated(dt)                 # TRUE on the 2nd+ copy of an identical row
  n_dup <- sum(dup)

  cat("---------------------------------------------------------\n")
  cat("FILE:", basename(f), "\n")
  cat("  rows total      :", nrow(dt), "\n")
  cat("  unique rows      :", nrow(dt) - n_dup, "\n")
  cat("  duplicate rows   :", n_dup,
      sprintf("(%.4f%%)", if (nrow(dt)) 100 * n_dup / nrow(dt) else 0), "\n")

  if (n_dup > 0L) {
    # Show up to 3 example duplicated rows (first few columns only, for legibility)
    ex <- unique(dt[dup])
    show_cols <- head(names(ex), 6L)
    cat("  example duplicate row(s) (first", length(show_cols), "cols):\n")
    print(head(ex[, ..show_cols], 3L))
  }
  cat("\n")

  parts[[i]] <- dt
}

# --- Combined inspection (only meaningful when there is >1 matched file) -----
if (length(files) > 1L) {
  # Bind only if every matched file has the same columns; otherwise they are
  # not parts of one logical table and a combined check would be meaningless.
  same_schema <- length(unique(lapply(parts, names))) == 1L
  if (same_schema) {
    combined <- rbindlist(parts)
    dup_c <- duplicated(combined)
    n_dup_c <- sum(dup_c)
    cat("=========================================================\n")
    cat("COMBINED across", length(files), "files\n")
    cat("  rows total      :", nrow(combined), "\n")
    cat("  unique rows      :", nrow(combined) - n_dup_c, "\n")
    cat("  duplicate rows   :", n_dup_c,
        sprintf("(%.4f%%)", if (nrow(combined)) 100 * n_dup_c / nrow(combined) else 0), "\n")
    cat("=========================================================\n")
  } else {
    cat("NOTE: matched files do not share identical column sets, so they are\n",
        "     reported individually only (no combined check).\n")
  }
}
