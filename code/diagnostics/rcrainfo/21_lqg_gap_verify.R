# =============================================================================
# 21_lqg_gap_verify.R  -- verify the gap explanations with real records + examples
# =============================================================================
suppressPackageStartupMessages(library(data.table))
YEARS <- 2015:2023; CYCLES <- seq(2015,2023,2)
HD_FILE <- "data/rcrainfo/hd/HD_HANDLER.csv"
BR_DIR  <- "data/rcrainfo/br"

## ---- HD_HANDLER FED=1 window rows (+ name/state for readable examples) ------
cols <- c("HANDLER ID","HANDLER NAME","LOCATION STATE","SOURCE TYPE","RECEIVE DATE",
          "REPORT CYCLE","FED WASTE GENERATOR","NON NOTIFIER","CURRENT RECORD")
hd <- fread(HD_FILE, select = cols, colClasses = "character", showProgress = FALSE)
setnames(hd, c("ID","NAME","ST","SRC","RDATE","RCYC","FED","NONNOT","CUR"))
hd[, ryr := suppressWarnings(as.integer(substr(RDATE,1,4)))]
lqg <- hd[FED=="1" & ryr %in% YEARS]

## ---- BR_REPORTING: unique (ID, cycle, status) ------------------------------
br <- rbindlist(lapply(CYCLES, function(y) {
  x <- fread(file.path(BR_DIR, sprintf("BR_REPORTING_%d.csv", y)),
             select=c("HANDLER ID","CALCULATED GENERATOR STATUS"),
             colClasses="character", showProgress=FALSE)
  setnames(x, c("ID","GEN")); unique(x)[, cyc := y]
}))
br_L_ids <- unique(br[GEN=="L"]$ID)

cat("\n== (A) CALCULATED GENERATOR STATUS code set (distinct facilities, pooled) ==\n")
print(br[, .(distinct_fac = uniqueN(ID)), by=GEN][order(-distinct_fac)])

handler_ids <- unique(lqg$ID)
missing <- setdiff(handler_ids, br_L_ids)
cat(sprintf("\nHandler-LQG=%d  missing(not BR-L)=%d\n", length(handler_ids), length(missing)))

## ---- (B) For MISSING set: best BR status they ever reach --------------------
mbr <- br[ID %in% missing]
best <- mbr[, .(statuses = paste(sort(unique(GEN)), collapse="")), by=ID]
cat("\n== (B) Missing facilities: their BR status signature (top) ==\n")
print(best[, .N, by=statuses][order(-N)][1:12])
cat(sprintf("Missing in BR at all: %d ; missing NOT in any BR: %d\n",
            uniqueN(mbr$ID), length(setdiff(missing, br$ID))))

## ---- (C) RECEIVE-year vs REPORT CYCLE for FED=1 records (even-year test) ----
cat("\n== (C) FED=1 records: RECEIVE-year vs REPORT CYCLE crosstab ==\n")
print(dcast(lqg[, .N, by=.(ryr, RCYC)], ryr ~ RCYC, value.var="N", fill=0))

## ---- helper: dump full trace for an ID -------------------------------------
trace_id <- function(id) {
  cat(sprintf("\n--- %s | %s | %s ---\n", id, hd[ID==id]$NAME[1], hd[ID==id]$ST[1]))
  cat("HD_HANDLER FED=1 rows (src/receive/cycle/nonnotifier/current):\n")
  print(lqg[ID==id, .(SRC, RDATE, RCYC, NONNOT, CUR)][order(RDATE)])
  b <- br[ID==id][order(cyc)]
  cat("BR_REPORTING (cycle:status):", if(nrow(b)) paste(b$cyc, b$GEN, sep=":", collapse="  ") else "<NONE>", "\n")
}

## ---- (D) pick deterministic examples per cause -----------------------------
fac <- lqg[, .(srcs=paste(sort(unique(SRC)),collapse=""),
               any_odd_cyc = any(RCYC %in% as.character(CYCLES)),
               any_oddyr   = any(ryr %% 2 == 1),
               any_evenyr  = any(ryr %% 2 == 0)), by=ID]
fac[, inBRany := ID %in% br$ID]
fac[, inBRL   := ID %in% br_L_ids]

pick <- function(cond, n=3) head(sort(fac[cond]$ID), n)

cat("\n##### CAUSE 1: notification-only (SRC=N), NEVER in any BR  (true non-filer) #####")
for (id in pick(fac$srcs=="N" & !fac$inBRany)) trace_id(id)

cat("\n##### CAUSE 2: in BR but computed non-LQG (paradox: self-declared LQG, BR<LQG) #####")
for (id in pick(fac$inBRany & !fac$inBRL & fac$srcs %like% "B")) trace_id(id)

cat("\n##### CAUSE 3: FED=1 in an ODD report cycle, yet missing from BR-L #####")
for (id in pick(fac$any_odd_cyc & !fac$inBRL)) trace_id(id)

cat("\n##### CAUSE 4: FED=1 only in EVEN receive-years -- inspect their REPORT CYCLE #####")
for (id in pick(fac$any_evenyr & !fac$any_oddyr & !fac$inBRL)) trace_id(id)
