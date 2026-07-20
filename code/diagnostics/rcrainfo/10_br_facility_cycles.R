suppressMessages(library(data.table))

dir <- "data/rcrainfo/br"
files <- list.files(dir, pattern = "^BR_REPORTING_[0-9]{4}[.]csv$", full.names = TRUE)

keys <- c("HANDLER ID", "ACTIVITY LOCATION", "SOURCE TYPE", "SEQ NUMBER", "REPORT CYCLE")

res <- list()
for (f in files) {
  dt <- fread(f, colClasses = "character", showProgress = FALSE)
  dt[, `:=`(.hz = suppressWarnings(as.numeric(`HZ PG`)),
            .sp = suppressWarnings(as.numeric(`SUB PAGE NUM`)))]
  g <- dt[, .(
      `HZ PG`                   = max(.hz, na.rm = TRUE),
      `SUB PAGE NUM`            = max(.sp, na.rm = TRUE),
      `GEN ID INCLUDED IN NBR`  = if (any(`GEN ID INCLUDED IN NBR`  == "Y")) "Y" else "N",
      `MGMT ID INCLUDED IN NBR` = if (any(`MGMT ID INCLUDED IN NBR` == "Y")) "Y" else "N",
      `SHIP ID INCLUDED IN NBR` = if (any(`SHIP ID INCLUDED IN NBR` == "Y")) "Y" else "N",
      `RECV ID INCLUDED IN NBR` = if (any(`RECV ID INCLUDED IN NBR` == "Y")) "Y" else "N",
      `GM FLAG`                 = if (any(`BR FORM` == "GM")) "Y" else "N",
      `WR FLAG`                 = if (any(`BR FORM` == "WR")) "Y" else "N",
      `XX FLAG`                 = if (any(`BR FORM` == "XX")) "Y" else "N"
    ), by = keys]
  g[is.infinite(`HZ PG`),        `HZ PG` := NA_real_]
  g[is.infinite(`SUB PAGE NUM`), `SUB PAGE NUM` := NA_real_]
  res[[f]] <- g
  cat(basename(f), "rows in:", nrow(dt), "facilities:", nrow(g), "\n")
}

out <- rbindlist(res)
setcolorder(out, c(keys, "HZ PG", "SUB PAGE NUM",
  "GEN ID INCLUDED IN NBR", "MGMT ID INCLUDED IN NBR", "SHIP ID INCLUDED IN NBR", "RECV ID INCLUDED IN NBR",
  "GM FLAG", "WR FLAG", "XX FLAG"))

dir.create("output/diagnostics", showWarnings = FALSE, recursive = TRUE)
fwrite(out, "output/diagnostics/BR_distinct_facilities_by_year.csv")
cat("TOTAL facility-year rows:", nrow(out), "\n")
