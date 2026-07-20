# =============================================================================
# 19_lqg_universe.R
#
# Question: how many distinct facilities (HANDLER ID) in the HANDLER module were
# identified AT LEAST ONCE during 2015-2023 as a federal Large Quantity
# Generator (LQG), and does the Biennial Report (BR) capture all of them?
#
# LQG definition follows the project convention (see
# code/diagnostics/rcrainfo/23_panel_facilities.R):
#     federal LQG  <=>  FED WASTE GENERATOR == "1"
#
# Handler-module universe is broader than HD_REPORTING: it uses the full
# HD_HANDLER form-submission table (notifications, Site ID forms, BR-sourced
# records, etc.), so a site reported LQG on ANY form received 2015-2023 counts.
# "Identified during 2015-2023" = RECEIVE DATE (YYYYMMDD) year in 2015..2023.
#
# Output -> output/diagnostics/
# =============================================================================

suppressPackageStartupMessages(library(data.table))

YEARS <- 2015:2023
HD_FILE <- "data/rcrainfo/hd/HD_HANDLER.csv"
BR_DIR  <- "data/rcrainfo/br"

# ---- 1. HD_HANDLER: full form-submission universe ---------------------------
hd_cols <- c("HANDLER ID", "SOURCE TYPE", "RECEIVE DATE", "REPORT CYCLE",
             "FED WASTE GENERATOR", "STATE WASTE GENERATOR", "CURRENT RECORD")

message("Reading HD_HANDLER ...")
hd <- fread(HD_FILE, select = hd_cols, colClasses = "character",
            showProgress = FALSE, encoding = "UTF-8")
setnames(hd, c("HANDLER_ID","SOURCE_TYPE","RECEIVE_DATE","REPORT_CYCLE",
               "FED_GEN","STATE_GEN","CURRENT_RECORD"))
message(sprintf("  HD_HANDLER rows: %s", format(nrow(hd), big.mark=",")))

hd[, rcv_year := suppressWarnings(as.integer(substr(RECEIVE_DATE, 1, 4)))]

# Federal LQG records received within the window
lqg_win <- hd[FED_GEN == "1" & rcv_year %in% YEARS]
handler_lqg_ids <- unique(lqg_win$HANDLER_ID)

message("\n================  HANDLER MODULE  ================")
message(sprintf("Federal-LQG form records received 2015-2023 : %s",
                format(nrow(lqg_win), big.mark=",")))
message(sprintf("DISTINCT facilities (HANDLER ID) = LQG >=1x   : %s",
                format(length(handler_lqg_ids), big.mark=",")))

# Breakdown: distinct LQG facilities first seen, by source type & by year
message("\nDistinct LQG facilities by RECEIVE-year (a site can appear in several):")
print(lqg_win[, .(distinct_facilities = uniqueN(HANDLER_ID)), by = rcv_year][order(rcv_year)])

message("\nLQG form records by SOURCE TYPE:")
print(lqg_win[, .(records = .N, distinct_fac = uniqueN(HANDLER_ID)), by = SOURCE_TYPE][order(-records)])

# ---- 2. BR side: LQGs the biennial report actually captured -----------------
br_lqg_ids <- character(0)
for (y in seq(2015, 2023, by = 2)) {
  f <- file.path(BR_DIR, sprintf("BR_REPORTING_%d.csv", y))
  if (!file.exists(f)) next
  br <- fread(f, select = c("HANDLER ID","CALCULATED GENERATOR STATUS"),
              colClasses = "character", showProgress = FALSE)
  setnames(br, c("HANDLER_ID","GEN"))
  ids <- unique(br[GEN == "L"]$HANDLER_ID)
  message(sprintf("  BR %d: %s LQG-reporting facilities", y, format(length(ids), big.mark=",")))
  br_lqg_ids <- union(br_lqg_ids, ids)
}
message(sprintf("DISTINCT BR LQG facilities 2015-2023 (status=L): %s",
                format(length(br_lqg_ids), big.mark=",")))

# ---- 3. Coverage gap --------------------------------------------------------
in_br      <- intersect(handler_lqg_ids, br_lqg_ids)
missing_br <- setdiff(handler_lqg_ids, br_lqg_ids)   # LQG in Handler module, never in a BR

message("\n================  COVERAGE  ================")
message(sprintf("Handler-module LQGs            : %s", format(length(handler_lqg_ids), big.mark=",")))
message(sprintf("  ... also in a BR (2015-2023) : %s (%.1f%%)",
                format(length(in_br), big.mark=","), 100*length(in_br)/length(handler_lqg_ids)))
message(sprintf("  ... NEVER in a BR            : %s (%.1f%%)",
                format(length(missing_br), big.mark=","), 100*length(missing_br)/length(handler_lqg_ids)))

# ---- 4. Write outputs -------------------------------------------------------
out <- data.table(HANDLER_ID = handler_lqg_ids)
out[, in_biennial_report := HANDLER_ID %in% br_lqg_ids]
dir.create("output/diagnostics", showWarnings = FALSE, recursive = TRUE)
fwrite(out, "output/diagnostics/lqg_handler_universe_2015_2023.csv")
fwrite(data.table(HANDLER_ID = missing_br),
       "output/diagnostics/lqg_handler_not_in_biennial_2015_2023.csv")
message("\nWrote: output/diagnostics/lqg_handler_universe_2015_2023.csv")
message("Wrote: output/diagnostics/lqg_handler_not_in_biennial_2015_2023.csv")
