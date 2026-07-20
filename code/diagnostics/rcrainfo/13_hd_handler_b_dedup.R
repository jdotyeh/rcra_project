suppressMessages(library(data.table))

flags <- c("FED WASTE GENERATOR", "TRANSPORTER", "TSD ACTIVITY")

dedup <- function(inp) {
  dt <- fread(inp, colClasses = "character", showProgress = FALSE)
  n0 <- nrow(dt)
  # within same HANDLER ID + REPORT CYCLE + identical flag combo: keep latest RECEIVE DATE
  # tie on date -> keep highest SEQ NUMBER
  dt[, `:=`(.d = as.integer(`RECEIVE DATE`), .s = as.integer(`SEQ NUMBER`))]
  setorderv(dt, c("HANDLER ID", "REPORT CYCLE", flags, ".d", ".s"))
  out <- dt[, .SD[.N], by = c("HANDLER ID", "REPORT CYCLE", flags)]
  out[, c(".d", ".s") := NULL]
  setcolorder(out, names(fread(inp, nrows = 0)))
  fwrite(out, inp)
  cat(basename(inp), ": ", n0, " -> ", nrow(out), "  (dropped ", n0 - nrow(out), ")\n", sep = "")
}

# The dup file only exists if an earlier ad-hoc split produced it.
for (f in c("output/diagnostics/HD_HANDLER_B_report_cycle.csv",
            "output/diagnostics/HD_HANDLER_B_dup_handler_cycle.csv")) {
  if (file.exists(f)) dedup(f) else cat("skip (not found):", f, "\n")
}
