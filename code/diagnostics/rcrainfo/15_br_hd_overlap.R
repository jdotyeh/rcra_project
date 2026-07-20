suppressMessages(library(data.table))

key <- c("HANDLER ID", "REPORT CYCLE")

br <- fread("output/diagnostics/BR_distinct_facilities_by_year.csv", colClasses = "character")
hd <- fread("output/diagnostics/HD_HANDLER_B_report_cycle.csv", colClasses = "character")

br_only <- br[!hd, on = key]
hd_only <- hd[!br, on = key]
both    <- merge(br, hd, by = key, suffixes = c(".BR", ".HD"))

fwrite(br_only, "output/diagnostics/BR_only_handler_cycle.csv")
fwrite(hd_only, "output/diagnostics/HD_only_handler_cycle.csv")
fwrite(both,    "output/diagnostics/BR_HD_both_handler_cycle.csv")

cat("BR_distinct:", nrow(br), " HANDLER_B:", nrow(hd), "\n")
cat("BR only :", nrow(br_only), "\n")
cat("HD only :", nrow(hd_only), "\n")
cat("both    :", nrow(both), "\n")
