# =============================================================================
# FILE:     05_hd_master_feasibility.R
# PURPOSE:  HD_MASTER build-feasibility check — inspect HD_HANDLER + linked tables for join-multiplication risks before the master-file stage runs.
# INPUTS:   data/rcrainfo/hd/*.csv
# OUTPUTS:  console prints (and any figure files noted inline below)
# AUTHOR:   Jason Ye
# CREATED:  2026-07
# UPDATED:  2026-07
# =============================================================================

## Feasibility check for a HANDLER-ID master file.
## Universe of facilities = distinct HANDLER ID in HD_HANDLER.csv.
## A facility stays ONE row in a cross-file master iff every OTHER module file
## holds <= 1 row for it. Any file with >= 2 rows multiplies that facility.
## Output: how many facilities appear no more than once in ALL other files.

suppressMessages(library(data.table))
setDTthreads(0)

dir <- "data/rcrainfo/hd"

## Other files keyed by HANDLER ID (exclude HD_HANDLER itself and HD_LU_* lookups).
all_csv <- list.files(dir, pattern = "\\.csv$", full.names = FALSE)
other   <- all_csv[grepl("^HD_", all_csv) &
                   all_csv != "HD_HANDLER.csv" &
                   !grepl("^HD_LU_", all_csv)]

## Universe.
hh <- fread(file.path(dir, "HD_HANDLER.csv"), select = 1L,
            colClasses = "character", showProgress = FALSE)
universe <- unique(hh[[1]])
universe <- universe[!is.na(universe) & universe != ""]
n_universe <- length(universe)
uni_set <- universe                       # for membership tests

## For each file: IDs that appear >= 2 times = the "multipliers".
multiplier_ids <- character(0)
per_file <- vector("list", length(other))

for (i in seq_along(other)) {
  f <- other[i]
  x <- fread(file.path(dir, f), select = 1L,
             colClasses = "character", showProgress = FALSE)[[1]]
  x <- x[!is.na(x) & x != ""]
  dup <- unique(x[duplicated(x)])         # IDs occurring >= 2 times in this file
  dup_in_uni <- dup[dup %chin% uni_set]   # restrict to facilities of interest
  multiplier_ids <- union(multiplier_ids, dup_in_uni)
  per_file[[i]] <- data.table(
    file            = f,
    rows            = length(x),
    distinct_ids    = uniqueN(x),
    ids_multi       = length(dup),        # ids with >=2 rows (any)
    ids_multi_inuni = length(dup_in_uni)  # ids with >=2 rows that are in universe
  )
  cat(sprintf("%-28s rows=%10s  multi_in_universe=%8s\n",
              f, format(length(x), big.mark=","),
              format(length(dup_in_uni), big.mark=",")), file = stderr())
}

per_file <- rbindlist(per_file)

n_multi   <- length(multiplier_ids)       # facilities that blow up in >=1 file
n_safe    <- n_universe - n_multi         # stay one row across ALL other files

cat("\n================ SUMMARY ================\n")
cat(sprintf("Distinct facilities (HD_HANDLER):        %s\n", format(n_universe, big.mark=",")))
cat(sprintf("Facilities multiplied by >=1 file:       %s\n", format(n_multi,    big.mark=",")))
cat(sprintf("Facilities <=1 row in ALL other files:   %s  (%.1f%%)\n",
            format(n_safe, big.mark=","), 100*n_safe/n_universe))
cat("========================================\n")

dir.create("output/diagnostics", showWarnings = FALSE, recursive = TRUE)
fwrite(per_file, "output/diagnostics/handler_master_feasibility_per_file.csv")
fwrite(data.table(
  distinct_facilities      = n_universe,
  facilities_multiplied    = n_multi,
  facilities_single_row    = n_safe,
  pct_single_row           = round(100*n_safe/n_universe, 2)
), "output/diagnostics/handler_master_feasibility_summary.csv")
