# =============================================================================
# FILE:     22_lqg_reverse_check.R
# PURPOSE:  LQG reverse check — confirm the balanced LQG universe by walking the panel back to its BR source rows.
# INPUTS:   data/rcrainfo/br/BR_REPORTING_*.csv, output/panels/BR_PANEL_2015_2023_BALANCED/*.csv
# OUTPUTS:  console prints (and any figure files noted inline below)
# AUTHOR:   Jason Ye
# CREATED:  2026-07
# UPDATED:  2026-07
# =============================================================================

# Reverse direction: of BR-LQG (calc-L >=1 cycle, 2015-2023), how many are also
# flagged LQG (FED WASTE GENERATOR=="1") in the Handler module?
suppressPackageStartupMessages(library(data.table))
# Panel year window; BR cycles inside it are odd years only.
YEARS <- 2015:2023; CYCLES <- seq(2015,2023,2)
HD_FILE <- "data/rcrainfo/hd/HD_HANDLER.csv"
BR_DIR  <- "data/rcrainfo/br"

# Slim HD_HANDLER slice for the check.
hd <- fread(HD_FILE, select=c("HANDLER ID","RECEIVE DATE","FED WASTE GENERATOR"),
            colClasses="character", showProgress=FALSE)
# Short column names + a receive-year helper for the window test.
setnames(hd, c("ID","RDATE","FED")); hd[, yr := suppressWarnings(as.integer(substr(RDATE,1,4)))]

# Handler-LQG within window
handler_lqg <- unique(hd[FED=="1" & yr %in% YEARS]$ID)
# Ever FED=1 (any date)
ever_fed1   <- unique(hd[FED=="1"]$ID)

# BR-LQG (calc-L, union)
# Union of handlers coded L in any cycle 2015-2023.
br_L <- unique(rbindlist(lapply(CYCLES, function(y){
  x <- fread(file.path(BR_DIR, sprintf("BR_REPORTING_%d.csv", y)),
             select=c("HANDLER ID","CALCULATED GENERATOR STATUS"),
             colClasses="character",showProgress=FALSE)
  setnames(x,c("ID","GEN")); unique(x[GEN=="L"])}))$ID)

# Match / mismatch partitions between BR-LQG and Handler-LQG.
both     <- intersect(br_L, handler_lqg)
not_hand <- setdiff(br_L, handler_lqg)               # BR-LQG but NOT FED=1 in window
# Print the top-line counts.
cat(sprintf("BR-LQG facilities (calc-L union)         : %d\n", length(br_L)))
cat(sprintf("  also Handler-LQG (FED=1 in 2015-2023)  : %d (%.1f%%)\n",
            length(both), 100*length(both)/length(br_L)))
cat(sprintf("  NOT Handler-LQG in window             : %d (%.1f%%)\n",
            length(not_hand), 100*length(not_hand)/length(br_L)))

# Characterize the non-matches
# Split non-matches into out-of-window LQGs and never-LQG handlers.
out_win <- intersect(not_hand, ever_fed1)            # registered LQG but only outside 2015-2023
never1  <- setdiff(not_hand, ever_fed1)              # never FED=1 at all
cat(sprintf("\n  of non-matches: FED=1 only OUTSIDE window : %d\n", length(out_win)))
cat(sprintf("                  never FED=1 in HD_HANDLER : %d\n", length(never1)))

# For never-FED=1: what federal status DO they carry (latest record)?
# For the never-FED=1 group, keep the most recent HD record per handler and
# tally the federal-generator codes they carry instead.
nv <- hd[ID %in% never1]
nv <- nv[order(ID, -RDATE)][, .SD[1], by=ID]
cat("\n  never-FED=1 group: latest FED WASTE GENERATOR value (blank shown as <empty>):\n")
print(nv[, .N, by=.(FED=fifelse(FED=="" | is.na(FED), "<empty>", FED))][order(-N)])
