# =============================================================================
# FILE:     12_hd_handler_b_cycles.R
# PURPOSE:  Handler-master B-record cycle diagnostic — how B (Biennial) source-typed records distribute across REPORT_CYCLE values in HD_HANDLER.
# INPUTS:   data/rcrainfo/hd/HD_HANDLER.csv
# OUTPUTS:  console prints (and any figure files noted inline below)
# AUTHOR:   Jason Ye
# CREATED:  2026-07
# UPDATED:  2026-07
# =============================================================================

# data.table for the wide HD_HANDLER read.
suppressMessages(library(data.table))

# Source-type B rows of HD_HANDLER (handler records sourced from a Biennial
# Report submission), with a REPORT CYCLE derived from the RECEIVE DATE year
# (even receive-years belong to the preceding odd cycle).
# Only the columns needed for the diagnostic, so the 2 GB HD_HANDLER read stays small.
cols <- c("HANDLER ID", "ACTIVITY LOCATION", "SOURCE TYPE", "SEQ NUMBER",
          "RECEIVE DATE", "HANDLER NAME",
          "FED WASTE GENERATOR", "TRANSPORTER", "TSD ACTIVITY")
dt <- fread("data/rcrainfo/hd/HD_HANDLER.csv", select = cols,
            colClasses = "character", showProgress = FALSE)
# Restrict to B rows (Biennial Report -> Handler updates).
dt <- dt[`SOURCE TYPE` == "B"]

# Receive-date year, then step even years down to the preceding odd cycle.
yr <- suppressWarnings(as.integer(substr(dt[["RECEIVE DATE"]], 1, 4)))
dt[, `REPORT CYCLE` := ifelse(is.na(yr), NA_integer_, ifelse(yr %% 2 == 1, yr, yr - 1L))]

# Final column order for the diagnostic export.
out_cols <- c("HANDLER ID", "ACTIVITY LOCATION", "SOURCE TYPE", "SEQ NUMBER",
              "RECEIVE DATE", "REPORT CYCLE", "HANDLER NAME",
              "FED WASTE GENERATOR", "TRANSPORTER", "TSD ACTIVITY")
out <- dt[, ..out_cols]

# Write the annotated B rows to the diagnostics folder.
dir.create("output/diagnostics", showWarnings = FALSE, recursive = TRUE)
fwrite(out, "output/diagnostics/HD_HANDLER_B_report_cycle.csv")
# Row count and how many rows had no parseable cycle.
cat("rows:", nrow(out), "  NA cycles:", sum(is.na(out[["REPORT CYCLE"]])), "\n")
