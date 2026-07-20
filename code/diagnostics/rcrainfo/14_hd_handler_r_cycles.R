suppressMessages(library(data.table))

hd <- fread("data/rcrainfo/hd/HD_HANDLER.csv",
            select = c("HANDLER ID", "ACTIVITY LOCATION", "SOURCE TYPE",
                       "SEQ NUMBER", "RECEIVE DATE", "HANDLER NAME",
                       "FED WASTE GENERATOR", "TRANSPORTER", "TSD ACTIVITY"),
            colClasses = "character", showProgress = FALSE)

dt <- hd[`SOURCE TYPE` == "R"]
yr <- suppressWarnings(as.integer(substr(dt[["RECEIVE DATE"]], 1, 4)))
dt[, `REPORT CYCLE` := ifelse(is.na(yr), NA_integer_, ifelse(yr %% 2 == 1, yr, yr - 1L))]

dir.create("output/diagnostics", showWarnings = FALSE, recursive = TRUE)
fwrite(dt, "output/diagnostics/HD_HANDLER_R_report_cycle.csv")
cat("rows:", nrow(dt), "  NA cycles:", sum(is.na(dt[["REPORT CYCLE"]])),
    "  distinct handler-cycles:", uniqueN(dt[!is.na(`REPORT CYCLE`),
                                             .(`HANDLER ID`, `REPORT CYCLE`)]), "\n")
