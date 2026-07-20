suppressMessages(library(data.table))

bro <- fread("output/diagnostics/BR_only_handler_cycle.csv", colClasses = "character",
             select = c("HANDLER ID", "REPORT CYCLE"))
combos <- unique(bro)
combos[, `:=`(y = as.integer(`REPORT CYCLE`))]
combos[, `:=`(lo = y * 10000L + 101L, hi = (y + 1L) * 10000L + 301L)]

raw <- fread("data/rcrainfo/hd/HD_HANDLER.csv", colClasses = "character",
             select = c("HANDLER ID", "ACTIVITY LOCATION", "SOURCE TYPE", "SEQ NUMBER",
                        "RECEIVE DATE", "HANDLER NAME", "FED WASTE GENERATOR",
                        "TRANSPORTER", "TSD ACTIVITY"))
raw <- raw[`SOURCE TYPE` == "B"]
raw[, d := suppressWarnings(as.integer(`RECEIVE DATE`))]

hit <- raw[combos, on = .(`HANDLER ID`, d >= lo, d < hi), nomatch = NULL,
           .(`HANDLER ID`, `RECEIVE DATE` = `x.RECEIVE DATE`,
             `FED WASTE GENERATOR`, `REPORT CYCLE` = `i.REPORT CYCLE`,
             `ACTIVITY LOCATION` = `x.ACTIVITY LOCATION`, `SOURCE TYPE` = `x.SOURCE TYPE`,
             `SEQ NUMBER` = `x.SEQ NUMBER`, `HANDLER NAME` = `x.HANDLER NAME`,
             `TRANSPORTER`, `TSD ACTIVITY`)]
setorder(hit, `HANDLER ID`, `REPORT CYCLE`, `RECEIVE DATE`)

fwrite(hit, "output/diagnostics/BR_only_HD_rows_window.csv")
cat("BR_only combos:", nrow(combos), "\n")
cat("rows pulled  :", nrow(hit), "\n")
cat("combos w >=1 row:", uniqueN(hit[, paste(`HANDLER ID`, `REPORT CYCLE`)]), "\n")
