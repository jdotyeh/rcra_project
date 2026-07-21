# =============================================================================
# FILE:     10_br_facility_cycles.R
# PURPOSE:  Biennial Report facility-cycle diagnostic — count facilities that appear in every cycle, in some cycles, and in one cycle.
# INPUTS:   data/rcrainfo/br/BR_REPORTING_*.csv
# OUTPUTS:  console prints (and any figure files noted inline below)
# AUTHOR:   Jason Ye
# CREATED:  2026-07
# UPDATED:  2026-07
# =============================================================================

# data.table for the memory-efficient reads and per-key aggregations.
suppressMessages(library(data.table))

# BR cycle files live under one folder; pick them up by regex.
dir <- "data/rcrainfo/br"
files <- list.files(dir, pattern = "^BR_REPORTING_[0-9]{4}[.]csv$", full.names = TRUE)

# Facility-cycle identity keys used by every aggregation below.
keys <- c("HANDLER ID", "ACTIVITY LOCATION", "SOURCE TYPE", "SEQ NUMBER", "REPORT CYCLE")

res <- list()
# Read each cycle, collapse to one row per facility-key, and stash the result.
for (f in files) {
  dt <- fread(f, colClasses = "character", showProgress = FALSE)
  # Parse the two numeric page-tracking columns into helper columns for max().
  dt[, `:=`(.hz = suppressWarnings(as.numeric(`HZ PG`)),
            .sp = suppressWarnings(as.numeric(`SUB PAGE NUM`)))]
  # One row per facility identity with flags rolled up to a "Y if any".
  g <- dt[, .(
      `HZ PG`                   = max(.hz, na.rm = TRUE),
      `SUB PAGE NUM`            = max(.sp, na.rm = TRUE),
      `GEN ID INCLUDED IN NBR`  = if (any(`GEN ID INCLUDED IN NBR`  == "Y")) "Y" else "N",
      `MGMT ID INCLUDED IN NBR` = if (any(`MGMT ID INCLUDED IN NBR` == "Y")) "Y" else "N",
      `SHIP ID INCLUDED IN NBR` = if (any(`SHIP ID INCLUDED IN NBR` == "Y")) "Y" else "N",
      `RECV ID INCLUDED IN NBR` = if (any(`RECV ID INCLUDED IN NBR` == "Y")) "Y" else "N",
      `GM FLAG`                 = if (any(`BR FORM` == "GM")) "Y" else "N",
      `WR FLAG`                 = if (any(`BR FORM` == "WR")) "Y" else "N",
      `XX FLAG`                 = if (any(`BR FORM` == "XX")) "Y" else "N"
    ), by = keys]
  # max() over an all-NA vector returns -Inf; restore NA on those rows.
  g[is.infinite(`HZ PG`),        `HZ PG` := NA_real_]
  g[is.infinite(`SUB PAGE NUM`), `SUB PAGE NUM` := NA_real_]
  res[[f]] <- g
  # Progress: raw-row and collapsed-facility counts for the cycle.
  cat(basename(f), "rows in:", nrow(dt), "facilities:", nrow(g), "\n")
}

# Stack every cycle back together and reorder to the diagnostic column layout.
out <- rbindlist(res)
setcolorder(out, c(keys, "HZ PG", "SUB PAGE NUM",
  "GEN ID INCLUDED IN NBR", "MGMT ID INCLUDED IN NBR", "SHIP ID INCLUDED IN NBR", "RECV ID INCLUDED IN NBR",
  "GM FLAG", "WR FLAG", "XX FLAG"))

# Write the facility-cycle table to the diagnostics folder for downstream scripts.
dir.create("output/diagnostics", showWarnings = FALSE, recursive = TRUE)
fwrite(out, "output/diagnostics/BR_distinct_facilities_by_year.csv")
cat("TOTAL facility-year rows:", nrow(out), "\n")
