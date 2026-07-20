# =============================================================================
# 27_lqg_strict_all5.R
# Strict set: facilities that are LQG in ALL 5 cycles (2015-2023) in BOTH the
# Biennial Report (CALCULATED GENERATOR STATUS == "L") and the Handler module
# (FED WASTE GENERATOR == "1", by report cycle). Tests whether requiring all-five
# agreement removes the registration-vs-calculated discrepancy.
#
# Reads the panel facility table (output/diagnostics/coherent_panel_facilities.csv,
# written by 23_panel_facilities.R), which already carries brL_<cycle> (BR-LQG)
# and LQG_<cycle> (Handler FED=1) per cycle.
# =============================================================================
suppressPackageStartupMessages(library(data.table))

d   <- fread("output/diagnostics/coherent_panel_facilities.csv",
             colClasses = list(character = "HANDLER_ID"))
brL <- c("brL_2015","brL_2017","brL_2019","brL_2021","brL_2023")
lqg <- c("LQG_2015","LQG_2017","LQG_2019","LQG_2021","LQG_2023")
d[, brL_n := rowSums(as.matrix(.SD)), .SDcols = brL]
d[, lqg_n := rowSums(as.matrix(.SD)), .SDcols = lqg]

cat(sprintf("At-least-once BR-LQG universe          : %d\n", nrow(d)))
cat(sprintf("BR-LQG all 5 cycles                    : %d\n", sum(d$brL_n == 5)))
cat(sprintf("Handler-LQG (FED=1) all 5 cycles       : %d\n", sum(d$lqg_n == 5)))
cat(sprintf("STRICT both all 5                      : %d\n", sum(d$brL_n == 5 & d$lqg_n == 5)))
cat(sprintf("Handler-all5 but NOT BR-all5           : %d\n", sum(d$lqg_n == 5 & d$brL_n < 5)))

cat("\nAmong BR-LQG-all5: #years also Handler-LQG:\n")
print(d[brL_n == 5, .N, by = lqg_n][order(lqg_n)])

fwrite(d[brL_n == 5 & lqg_n == 5, .(HANDLER_ID)],
       "output/diagnostics/lqg_strict_all5_both.csv")
cat(sprintf("\nWrote output/diagnostics/lqg_strict_all5_both.csv (%d ids)\n",
            sum(d$brL_n == 5 & d$lqg_n == 5)))
