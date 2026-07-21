# =============================================================================
# FILE:     13_hd_handler_b_dedup.R
# PURPOSE:  Handler-master B-record dedup diagnostic — check whether B records duplicate across HANDLER_ID + REPORT_CYCLE.
# INPUTS:   data/rcrainfo/hd/HD_HANDLER.csv
# OUTPUTS:  console prints (and any figure files noted inline below)
# AUTHOR:   Jason Ye
# CREATED:  2026-07
# UPDATED:  2026-07
# =============================================================================

# data.table for the in-place ordering and by-group slice.
suppressMessages(library(data.table))

# Flag columns that participate in the "identical flag combo" dedup key.
flags <- c("FED WASTE GENERATOR", "TRANSPORTER", "TSD ACTIVITY")

# Deduplicate one file in place: collapse identical flag rows to the latest one.
dedup <- function(inp) {
  dt <- fread(inp, colClasses = "character", showProgress = FALSE)
  n0 <- nrow(dt)
  # within same HANDLER ID + REPORT CYCLE + identical flag combo: keep latest RECEIVE DATE
  # tie on date -> keep highest SEQ NUMBER
  # Cast the date and sequence to integers so setorderv sorts them numerically.
  dt[, `:=`(.d = as.integer(`RECEIVE DATE`), .s = as.integer(`SEQ NUMBER`))]
  setorderv(dt, c("HANDLER ID", "REPORT CYCLE", flags, ".d", ".s"))
  # Take the last row per group (winner after the sort).
  out <- dt[, .SD[.N], by = c("HANDLER ID", "REPORT CYCLE", flags)]
  # Drop the helper columns and restore the original column order.
  out[, c(".d", ".s") := NULL]
  setcolorder(out, names(fread(inp, nrows = 0)))
  # Overwrite the input file with the deduped output and log the shrink.
  fwrite(out, inp)
  cat(basename(inp), ": ", n0, " -> ", nrow(out), "  (dropped ", n0 - nrow(out), ")\n", sep = "")
}

# The dup file only exists if an earlier ad-hoc split produced it.
for (f in c("output/diagnostics/HD_HANDLER_B_report_cycle.csv",
            "output/diagnostics/HD_HANDLER_B_dup_handler_cycle.csv")) {
  if (file.exists(f)) dedup(f) else cat("skip (not found):", f, "\n")
}
