suppressMessages(library(data.table))

# Source-type B rows of HD_HANDLER (handler records sourced from a Biennial
# Report submission), with a REPORT CYCLE derived from the RECEIVE DATE year
# (even receive-years belong to the preceding odd cycle).
cols <- c("HANDLER ID", "ACTIVITY LOCATION", "SOURCE TYPE", "SEQ NUMBER",
          "RECEIVE DATE", "HANDLER NAME",
          "FED WASTE GENERATOR", "TRANSPORTER", "TSD ACTIVITY")
dt <- fread("data/rcrainfo/hd/HD_HANDLER.csv", select = cols,
            colClasses = "character", showProgress = FALSE)
dt <- dt[`SOURCE TYPE` == "B"]

yr <- suppressWarnings(as.integer(substr(dt[["RECEIVE DATE"]], 1, 4)))
dt[, `REPORT CYCLE` := ifelse(is.na(yr), NA_integer_, ifelse(yr %% 2 == 1, yr, yr - 1L))]

out_cols <- c("HANDLER ID", "ACTIVITY LOCATION", "SOURCE TYPE", "SEQ NUMBER",
              "RECEIVE DATE", "REPORT CYCLE", "HANDLER NAME",
              "FED WASTE GENERATOR", "TRANSPORTER", "TSD ACTIVITY")
out <- dt[, ..out_cols]

dir.create("output/diagnostics", showWarnings = FALSE, recursive = TRUE)
fwrite(out, "output/diagnostics/HD_HANDLER_B_report_cycle.csv")
cat("rows:", nrow(out), "  NA cycles:", sum(is.na(out[["REPORT CYCLE"]])), "\n")
