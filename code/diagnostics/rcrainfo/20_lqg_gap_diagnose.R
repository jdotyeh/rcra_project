# =============================================================================
# 20_lqg_gap_diagnose.R
# Why do 42,027 Handler-module federal-LQG facilities never appear in a BR
# (2015-2023) as LQG? Characterize the missing set from HD_HANDLER.
# =============================================================================
suppressPackageStartupMessages(library(data.table))
YEARS <- 2015:2023
HD_FILE <- "data/rcrainfo/hd/HD_HANDLER.csv"
BR_DIR  <- "data/rcrainfo/br"

cols <- c("HANDLER ID","SOURCE TYPE","RECEIVE DATE","FED WASTE GENERATOR",
          "NON NOTIFIER","CURRENT RECORD")
hd <- fread(HD_FILE, select = cols, colClasses = "character", showProgress = FALSE)
setnames(hd, c("ID","SRC","RDATE","FED","NONNOT","CUR"))
hd[, yr := suppressWarnings(as.integer(substr(RDATE,1,4)))]

lqg <- hd[FED=="1" & yr %in% YEARS]
handler_ids <- unique(lqg$ID)

# BR LQG ids
br_ids <- character(0)
for (y in seq(2015,2023,2)) {
  br <- fread(file.path(BR_DIR, sprintf("BR_REPORTING_%d.csv", y)),
              select=c("HANDLER ID","CALCULATED GENERATOR STATUS"),
              colClasses="character", showProgress=FALSE)
  setnames(br, c("ID","GEN"))
  br_ids <- union(br_ids, unique(br[GEN=="L"]$ID))
}
missing <- setdiff(handler_ids, br_ids)
lqg[, grp := fifelse(ID %in% br_ids, "in_BR", "never_in_BR")]
cat(sprintf("Handler-LQG=%d  in_BR=%d  missing=%d\n",
            length(handler_ids), length(intersect(handler_ids,br_ids)), length(missing)))

# (1) per-facility: which source types, year parity of their LQG flags
fac <- lqg[, .(srcs = paste(sort(unique(SRC)),collapse=""),
               n_rec = .N,
               any_odd  = any(yr %% 2 == 1),
               any_even = any(yr %% 2 == 0),
               only_N   = all(SRC=="N"),
               ever_noncur_only = all(CUR!="Y")),
           by=ID]
fac[, grp := fifelse(ID %in% br_ids, "in_BR","never_in_BR")]

cat("\n-- (1) Year parity of FED=1 records, by group (distinct facilities) --\n")
print(fac[, .(facilities=.N,
              only_even_year = sum(any_even & !any_odd),
              only_odd_year  = sum(any_odd & !any_even),
              both           = sum(any_odd & any_even)), by=grp])

cat("\n-- (2) Missing facilities whose LQG flag is ONLY from notification (SRC=N) --\n")
print(fac[grp=="never_in_BR", .(facilities=.N, only_N=sum(only_N),
                                pct_only_N=round(100*mean(only_N),1))])

cat("\n-- (3) Source-type signature among missing facilities (top) --\n")
print(fac[grp=="never_in_BR", .N, by=srcs][order(-N)][1:10])

cat("\n-- (4) Records-per-missing-facility (one-off vs repeated) --\n")
print(fac[grp=="never_in_BR", .(one_record=sum(n_rec==1),
                                two_to_four=sum(n_rec %in% 2:4),
                                five_plus=sum(n_rec>=5))])

# (5) Of missing: do they appear in HD_REPORTING at all (any status)?
r <- fread("data/rcrainfo/hd/HD_REPORTING.csv", select="HANDLER ID",
           colClasses="character", showProgress=FALSE)
rep_ids <- unique(r[[1]])
cat(sprintf("\n-- (5) Of %d missing, appear in HD_REPORTING (any gen status): %d (%.1f%%) --\n",
    length(missing), length(intersect(missing,rep_ids)),
    100*length(intersect(missing,rep_ids))/length(missing)))
