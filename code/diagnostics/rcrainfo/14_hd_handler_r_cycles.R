# =============================================================================
# FILE:     14_hd_handler_r_cycles.R
# PURPOSE:  Handler-master R-record cycle diagnostic — mirror of 12_hd_handler_b_cycles.R for R (Report update) source types.
# INPUTS:   data/rcrainfo/hd/HD_HANDLER.csv
# OUTPUTS:  console prints (and any figure files noted inline below)
# AUTHOR:   Jason Ye
# CREATED:  2026-07
# UPDATED:  2026-07
# =============================================================================

# data.table for the wide HD_HANDLER read.
suppressMessages(library(data.table))

# Pull only the columns needed for the R-record diagnostic, all as character.
hd <- fread("data/rcrainfo/hd/HD_HANDLER.csv",
            select = c("HANDLER ID", "ACTIVITY LOCATION", "SOURCE TYPE",
                       "SEQ NUMBER", "RECEIVE DATE", "HANDLER NAME",
                       "FED WASTE GENERATOR", "TRANSPORTER", "TSD ACTIVITY"),
            colClasses = "character", showProgress = FALSE)

# Restrict to R rows (Report-update source type).
dt <- hd[`SOURCE TYPE` == "R"]
# Receive-date year, then step even years down to the preceding odd cycle.
yr <- suppressWarnings(as.integer(substr(dt[["RECEIVE DATE"]], 1, 4)))
dt[, `REPORT CYCLE` := ifelse(is.na(yr), NA_integer_, ifelse(yr %% 2 == 1, yr, yr - 1L))]

# Write the annotated R rows to the diagnostics folder.
dir.create("output/diagnostics", showWarnings = FALSE, recursive = TRUE)
fwrite(dt, "output/diagnostics/HD_HANDLER_R_report_cycle.csv")
# Row count, unparseable-cycle count, and distinct handler-cycle pairs.
cat("rows:", nrow(dt), "  NA cycles:", sum(is.na(dt[["REPORT CYCLE"]])),
    "  distinct handler-cycles:", uniqueN(dt[!is.na(`REPORT CYCLE`),
                                             .(`HANDLER ID`, `REPORT CYCLE`)]), "\n")
