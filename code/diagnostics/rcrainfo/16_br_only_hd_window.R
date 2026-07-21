# =============================================================================
# FILE:     16_br_only_hd_window.R
# PURPOSE:  BR-only handlers within a HD window — restrict the BR-only set to handlers whose HD receive dates fall in a target range.
# INPUTS:   data/rcrainfo/br/BR_REPORTING_*.csv, data/rcrainfo/hd/HD_HANDLER.csv
# OUTPUTS:  console prints (and any figure files noted inline below)
# AUTHOR:   Jason Ye
# CREATED:  2026-07
# UPDATED:  2026-07
# =============================================================================

# data.table for the non-equi range join.
suppressMessages(library(data.table))

# BR-only handler-cycle pairs (built by 15_br_hd_overlap.R).
bro <- fread("output/diagnostics/BR_only_handler_cycle.csv", colClasses = "character",
             select = c("HANDLER ID", "REPORT CYCLE"))
combos <- unique(bro)
# For each cycle year y, build a yyyymmdd window from Jan 1 of y through Mar 1
# of y+1 so a filing that arrives shortly after the cycle end still matches.
combos[, `:=`(y = as.integer(`REPORT CYCLE`))]
combos[, `:=`(lo = y * 10000L + 101L, hi = (y + 1L) * 10000L + 301L)]

# HD_HANDLER, restricted to B rows so the join stays modest.
raw <- fread("data/rcrainfo/hd/HD_HANDLER.csv", colClasses = "character",
             select = c("HANDLER ID", "ACTIVITY LOCATION", "SOURCE TYPE", "SEQ NUMBER",
                        "RECEIVE DATE", "HANDLER NAME", "FED WASTE GENERATOR",
                        "TRANSPORTER", "TSD ACTIVITY"))
raw <- raw[`SOURCE TYPE` == "B"]
# Parse receive date to yyyymmdd integer for the range join.
raw[, d := suppressWarnings(as.integer(`RECEIVE DATE`))]

# Non-equi join: pull every HD row whose receive date sits inside the cycle window.
hit <- raw[combos, on = .(`HANDLER ID`, d >= lo, d < hi), nomatch = NULL,
           .(`HANDLER ID`, `RECEIVE DATE` = `x.RECEIVE DATE`,
             `FED WASTE GENERATOR`, `REPORT CYCLE` = `i.REPORT CYCLE`,
             `ACTIVITY LOCATION` = `x.ACTIVITY LOCATION`, `SOURCE TYPE` = `x.SOURCE TYPE`,
             `SEQ NUMBER` = `x.SEQ NUMBER`, `HANDLER NAME` = `x.HANDLER NAME`,
             `TRANSPORTER`, `TSD ACTIVITY`)]
# Sort for a stable output.
setorder(hit, `HANDLER ID`, `REPORT CYCLE`, `RECEIVE DATE`)

# Write the window-restricted rows and report the row / combo counts.
fwrite(hit, "output/diagnostics/BR_only_HD_rows_window.csv")
cat("BR_only combos:", nrow(combos), "\n")
cat("rows pulled  :", nrow(hit), "\n")
cat("combos w >=1 row:", uniqueN(hit[, paste(`HANDLER ID`, `REPORT CYCLE`)]), "\n")
