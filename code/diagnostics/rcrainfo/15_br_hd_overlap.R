# =============================================================================
# FILE:     15_br_hd_overlap.R
# PURPOSE:  BR / HD overlap diagnostic — which HANDLER_IDs appear in BR_REPORTING but not in HD_HANDLER (and vice versa).
# INPUTS:   data/rcrainfo/br/BR_REPORTING_*.csv, data/rcrainfo/hd/HD_HANDLER.csv
# OUTPUTS:  console prints (and any figure files noted inline below)
# AUTHOR:   Jason Ye
# CREATED:  2026-07
# UPDATED:  2026-07
# =============================================================================

# data.table for the anti-join and merge helpers.
suppressMessages(library(data.table))

# Facility-cycle identity used by every join below.
key <- c("HANDLER ID", "REPORT CYCLE")

# Two sides of the overlap, both built by the earlier diagnostics.
br <- fread("output/diagnostics/BR_distinct_facilities_by_year.csv", colClasses = "character")
hd <- fread("output/diagnostics/HD_HANDLER_B_report_cycle.csv", colClasses = "character")

# Set-difference and intersection on the shared key.
br_only <- br[!hd, on = key]
hd_only <- hd[!br, on = key]
both    <- merge(br, hd, by = key, suffixes = c(".BR", ".HD"))

# Persist each partition for downstream diagnostics.
fwrite(br_only, "output/diagnostics/BR_only_handler_cycle.csv")
fwrite(hd_only, "output/diagnostics/HD_only_handler_cycle.csv")
fwrite(both,    "output/diagnostics/BR_HD_both_handler_cycle.csv")

# Row counts, so the three shares add up to (br + hd) minus overlap.
cat("BR_distinct:", nrow(br), " HANDLER_B:", nrow(hd), "\n")
cat("BR only :", nrow(br_only), "\n")
cat("HD only :", nrow(hd_only), "\n")
cat("both    :", nrow(both), "\n")
