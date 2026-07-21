# =============================================================================
# FILE:     11_br_facility_cycles_dedup.R
# PURPOSE:  Biennial Report facility-cycle diagnostic (dedup edition) — the same counts as 10_br_facility_cycles.R, but with per-cycle deduplication applied first.
# INPUTS:   data/rcrainfo/br/BR_REPORTING_*.csv
# OUTPUTS:  console prints (and any figure files noted inline below)
# AUTHOR:   Jason Ye
# CREATED:  2026-07
# UPDATED:  2026-07
# =============================================================================

suppressMessages(library(data.table))

br <- fread("output/diagnostics/BR_distinct_facilities_by_year.csv", colClasses = "character")
n0 <- nrow(br)
br[, grp := paste(`HANDLER ID`, `REPORT CYCLE`)]

ycols <- c("GEN ID INCLUDED IN NBR", "MGMT ID INCLUDED IN NBR", "SHIP ID INCLUDED IN NBR",
           "RECV ID INCLUDED IN NBR", "GM FLAG", "WR FLAG", "XX FLAG")

exact <- c("MOD058923269 2023", "NJR986652188 2023")
compl <- c("CAD981426836 2021", "CAR000032946 2019", "CAR000056705 2019", "CAR000228650 2023",
           "MDD050920347 2021", "MDD985366889 2021", "MDR000526147 2021", "NYR000007971 2023")

merge_rows <- function(g) {
  out <- g[which.max(as.integer(`SEQ NUMBER`))]
  out[, `HZ PG` := as.character(max(as.numeric(g[["HZ PG"]]), na.rm = TRUE))]
  out[, `SUB PAGE NUM` := as.character(max(as.numeric(g[["SUB PAGE NUM"]]), na.rm = TRUE))]
  for (cc in ycols) set(out, j = cc, value = if (any(g[[cc]] == "Y")) "Y" else "N")
  st <- unique(g[["CALCULATED GENERATOR STATUS"]])
  if (length(st) > 1) {
    gm <- g[`GM FLAG` == "Y", `CALCULATED GENERATOR STATUS`]
    set(out, j = "CALCULATED GENERATOR STATUS", value = if (length(unique(gm)) == 1) gm[1] else st[1])
    cat("  status conflict in", g$grp[1], ":", paste(st, collapse = "/"),
        "-> kept", out[["CALCULATED GENERATOR STATUS"]], "\n")
  }
  out
}

results <- list()

for (cb in exact) {
  g <- br[grp == cb]
  results[[cb]] <- g[which.max(as.integer(`SEQ NUMBER`))]
  cat("exact  ", cb, ": kept SEQ", results[[cb]]$`SEQ NUMBER`, "\n")
}

for (cb in compl) {
  g <- br[grp == cb]
  results[[cb]] <- merge_rows(g)
  cat("merge  ", cb, ": SEQ ->", results[[cb]]$`SEQ NUMBER`, "\n")
}

g <- br[grp == "CAD983670670 2021"]
gm  <- g[`GM FLAG` == "Y"]
xx  <- g[`XX FLAG` == "Y"][which.max(as.integer(`SEQ NUMBER`))]
results[["CAD983670670 2021"]] <- merge_rows(rbind(gm, xx))
cat("special CAD983670670: GM SEQ", gm$`SEQ NUMBER`, "+ XX SEQ", xx$`SEQ NUMBER`,
    "-> SEQ", results[["CAD983670670 2021"]]$`SEQ NUMBER`, "\n")

g <- br[grp == "OHD048415665 2021"]
results[["OHD048415665 2021"]] <- merge_rows(g)
cat("special OHD048415665: merged -> SEQ", results[["OHD048415665 2021"]]$`SEQ NUMBER`, "\n")

resolved <- names(results)
res_dt <- rbindlist(results)
br2 <- rbind(br[!grp %in% resolved], res_dt)
setorder(br2, `REPORT CYCLE`, `HANDLER ID`)

ctd <- br2[grp == "CTD054476973 2023"]

br2[, grp := NULL]
fwrite(br2, "output/diagnostics/BR_distinct_facilities_by_year.csv")
cat("BR_distinct:", n0, "->", nrow(br2), "\n")

dupout <- rbind(res_dt, ctd)
setorder(dupout, `HANDLER ID`, `REPORT CYCLE`)
dupout[, grp := NULL]
fwrite(dupout, "output/diagnostics/BR_distinct_dup_handler_cycle.csv")
cat("dup file rows:", nrow(dupout), "(11 resolved + 2 CTD unresolved)\n")

raw <- fread("data/rcrainfo/br/BR_REPORTING_2023.csv",
             colClasses = "character", showProgress = FALSE)
x <- raw[`HANDLER ID` == "CTD054476973" & `SEQ NUMBER` %in% c("8", "9")]
fwrite(x, "output/diagnostics/CTD054476973_2023_seq8_9_raw.csv")
cat("CTD raw rows extracted:", nrow(x), "\n")
