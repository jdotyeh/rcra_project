# =============================================================================
# 03_hd_reporting_integrity.R
# Data-integrity / anomaly scan of HD_REPORTING beyond the known
# "multiple handler IDs -> same physical site" issue.
# Output: console report + output/diagnostics/hd_reporting_integrity/*.csv
# flagged samples
# =============================================================================
suppressPackageStartupMessages({library(data.table)})

out_dir <- "output/diagnostics/hd_reporting_integrity"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

keep <- c("HANDLER ID","ACTIVITY LOCATION","SOURCE TYPE","SEQ NUMBER","HANDLER NAME",
          "NON NOTIFIER","RECEIVE DATE","REGION","STATE","ACTIVE SITE",
          "LOCATION STREET NO","LOCATION STREET1","LOCATION CITY","LOCATION STATE",
          "LOCATION ZIP","LOCATION COUNTY NAME","LOCATION COUNTRY",
          "MAIL STATE","MAIL ZIP",
          "LOCATION LATITUDE","LOCATION LONGITUDE","LOCATION GIS PRIMARY",
          "LOCATION GIS ORIGIN","HHANDLER LAST CHANGE")

dt <- fread("data/rcrainfo/hd/HD_REPORTING.csv", select = keep,
            colClasses = "character", showProgress = FALSE)
setnames(dt, gsub(" ", "_", names(dt)))
N <- nrow(dt)
cat(sprintf("Loaded %s rows, %d cols\n\n", format(N, big.mark=","), ncol(dt)))

rep <- function(...) cat(sprintf(...))
samp <- function(d, name, n=200) {
  if (nrow(d)) fwrite(head(d, n), file.path(out_dir, paste0(name, ".csv")))
}
lat <- suppressWarnings(as.numeric(dt$LOCATION_LATITUDE))
lon <- suppressWarnings(as.numeric(dt$LOCATION_LONGITUDE))

cat("================ KEY / UNIQUENESS ================\n")
# 1. distinct handler IDs vs rows (one row per site claim)
nid <- uniqueN(dt$HANDLER_ID)
rep("HANDLER_ID: %s distinct of %s rows -> %s rows share an ID\n",
    format(nid,big.mark=","), format(N,big.mark=","), format(N-nid,big.mark=","))
dupid <- dt[, .N, by=HANDLER_ID][N>1]
rep("  HANDLER_IDs appearing >1x: %s (max %d rows for one ID)\n",
    format(nrow(dupid),big.mark=","), if(nrow(dupid)) max(dupid$N) else 0L)
samp(dt[HANDLER_ID %in% head(dupid[order(-N)]$HANDLER_ID, 50)][order(HANDLER_ID)],
     "dup_handler_id")

# 2. candidate composite key
key4 <- c("HANDLER_ID","ACTIVITY_LOCATION","SOURCE_TYPE","SEQ_NUMBER")
nk <- uniqueN(dt[, ..key4])
rep("Composite key (ID+ACTIVITY+SOURCE+SEQ): %s distinct -> %s collisions\n",
    format(nk,big.mark=","), format(N-nk,big.mark=","))
dupkey <- dt[, .N, by=key4][N>1]
samp(merge(dt, dupkey[,..key4], by=key4)[order(HANDLER_ID)], "dup_composite_key")
rep("  composite-key collisions: %s row-groups\n", format(nrow(dupkey),big.mark=","))

# 3. fully duplicated rows
ndup_full <- N - uniqueN(dt)
rep("Fully duplicated rows (all %d cols identical): %s\n\n", ncol(dt),
    format(ndup_full,big.mark=","))

cat("================ HANDLER_ID FORMAT ================\n")
id <- dt$HANDLER_ID
nlen <- dt[nchar(HANDLER_ID)!=12, .N]
rep("HANDLER_ID not 12 chars: %s (lengths: %s)\n", format(nlen,big.mark=","),
    paste(sort(unique(nchar(id))), collapse=","))
badfmt <- !grepl("^[A-Z]{2}[A-Z0-9]{10}$", id)
rep("HANDLER_ID failing ^[A-Z]{2}[A-Z0-9]{10}$ : %s\n", format(sum(badfmt),big.mark=","))
samp(dt[badfmt], "bad_id_format")
# prefix vs ACTIVITY_LOCATION
pre <- substr(id,1,2)
mm <- dt[pre != ACTIVITY_LOCATION &
         !ACTIVITY_LOCATION %in% c("","NA")]
rep("ID 2-letter prefix != ACTIVITY_LOCATION: %s (e.g. prefixes %s)\n",
    format(nrow(mm),big.mark=","),
    paste(head(unique(paste0(substr(mm$HANDLER_ID,1,2),"->",mm$ACTIVITY_LOCATION)),6),collapse=", "))
samp(mm[, .(HANDLER_ID,ACTIVITY_LOCATION,STATE,LOCATION_STATE,HANDLER_NAME)], "id_prefix_vs_activity")
cat("\n")

cat("================ MULTI-ID -> SAME SITE (variants) ================\n")
norm <- function(x) toupper(trimws(gsub("\\s+"," ", x)))
# a. same coordinates, different IDs
g <- data.table(HANDLER_ID=dt$HANDLER_ID, lat=lat, lon=lon,
                addr=norm(paste(dt$LOCATION_STREET_NO,dt$LOCATION_STREET1,
                                dt$LOCATION_CITY,dt$LOCATION_STATE,dt$LOCATION_ZIP)),
                name=norm(dt$HANDLER_NAME))
gc_ll <- g[!is.na(lat)&!is.na(lon)&!(lat==0&lon==0),
           .(nid=uniqueN(HANDLER_ID)), by=.(lat=round(lat,5),lon=round(lon,5))][nid>1]
rep("Distinct coordinates shared by >1 HANDLER_ID: %s (covering %s ID-pairs)\n",
    format(nrow(gc_ll),big.mark=","), format(sum(gc_ll$nid),big.mark=","))
# b. same full street address, different IDs
gc_ad <- g[addr!="" & nchar(addr)>8, .(nid=uniqueN(HANDLER_ID)), by=addr][nid>1]
rep("Distinct street addresses shared by >1 HANDLER_ID: %s (max %d IDs at one addr)\n",
    format(nrow(gc_ad),big.mark=","), if(nrow(gc_ad)) max(gc_ad$nid) else 0L)
samp(g[addr %in% head(gc_ad[order(-nid)]$addr,40)][order(addr)], "multi_id_same_address")
# c. identical handler name at >1 ID (chains vs dup)
gc_nm <- g[name!="", .(nid=uniqueN(HANDLER_ID)), by=name][nid>1][order(-nid)]
rep("Handler NAMES used by >1 HANDLER_ID: %s (top: '%s' x%d)\n\n",
    format(nrow(gc_nm),big.mark=","), if(nrow(gc_nm)) gc_nm$name[1] else "",
    if(nrow(gc_nm)) gc_nm$nid[1] else 0L)
samp(gc_nm, "dup_names")

cat("================ COORDINATE ANOMALIES ================\n")
rep("lat/lon both present: %s ; both missing: %s\n",
    format(sum(!is.na(lat)&!is.na(lon)),big.mark=","),
    format(sum(is.na(lat)&is.na(lon)),big.mark=","))
rep("exactly one of lat/lon missing: %s\n", format(sum(xor(is.na(lat),is.na(lon))),big.mark=","))
rep("lat==0 & lon==0 (null island): %s\n", format(sum(lat==0&lon==0,na.rm=TRUE),big.mark=","))
rep("lat out of [-90,90]: %s ; lon out of [-180,180]: %s\n",
    format(sum(lat< -90|lat>90,na.rm=TRUE),big.mark=","),
    format(sum(lon< -180|lon>180,na.rm=TRUE),big.mark=","))
# US contiguous-ish: lat 17-72, lon -180..-65. Positive lon in US data = sign error
poslon <- dt[!is.na(lon) & lon>0 & LOCATION_COUNTRY %in% c("","US","USA")]
rep("positive longitude w/ US/blank country: %s (likely dropped '-')\n", format(nrow(poslon),big.mark=","))
samp(poslon[,.(HANDLER_ID,LOCATION_STATE,LOCATION_LATITUDE,LOCATION_LONGITUDE,HANDLER_NAME)],"positive_longitude")
# lat/lon possibly swapped: lon positive & small, lat very negative (US sites)
swap <- sum(!is.na(lat)&!is.na(lon) & lon > -65 & lon < 65 & lat < -65)
rep("possible lat/lon swap (lat very negative, lon small): %s\n", format(swap,big.mark=","))
# low-precision coords (integer-valued) -> imprecise geocode
intll <- dt[!is.na(lat)&!is.na(lon) & lat==round(lat) & lon==round(lon) & !(lat==0&lon==0)]
rep("integer-valued lat AND lon (low precision): %s\n\n", format(nrow(intll),big.mark=","))
samp(intll[,.(HANDLER_ID,LOCATION_STATE,LOCATION_LATITUDE,LOCATION_LONGITUDE,LOCATION_GIS_ORIGIN)],"integer_coords")

cat("================ GEOGRAPHIC CONSISTENCY ================\n")
ms <- dt[LOCATION_STATE!="" & STATE!="" & LOCATION_STATE!=STATE]
rep("LOCATION_STATE != STATE: %s\n", format(nrow(ms),big.mark=","))
samp(ms[,.(HANDLER_ID,STATE,LOCATION_STATE,ACTIVITY_LOCATION,LOCATION_CITY)],"state_mismatch")
ma <- dt[LOCATION_STATE!="" & ACTIVITY_LOCATION!="" & LOCATION_STATE!=ACTIVITY_LOCATION]
rep("LOCATION_STATE != ACTIVITY_LOCATION: %s\n", format(nrow(ma),big.mark=","))
# ZIP format
zip <- dt$LOCATION_ZIP
badzip <- dt[LOCATION_ZIP!="" & !grepl("^[0-9]{5}([0-9]{4})?$", LOCATION_ZIP) &
             LOCATION_COUNTRY %in% c("","US","USA")]
rep("LOCATION_ZIP malformed (US): %s\n", format(nrow(badzip),big.mark=","))
samp(badzip[,.(HANDLER_ID,LOCATION_STATE,LOCATION_ZIP,LOCATION_COUNTRY)],"bad_zip")
rep("LOCATION_ZIP == 00000: %s\n\n", format(sum(zip=="00000"),big.mark=","))

cat("================ DATE ANOMALIES ================\n")
rd <- dt$RECEIVE_DATE
rdn <- suppressWarnings(as.integer(rd))
rep("RECEIVE_DATE blank: %s ; non-8-digit: %s\n",
    format(sum(rd==""),big.mark=","),
    format(sum(rd!="" & !grepl("^[0-9]{8}$",rd)),big.mark=","))
rep("RECEIVE_DATE in future (>20260622): %s ; before 19800101: %s\n",
    format(sum(rdn>20260622,na.rm=TRUE),big.mark=","),
    format(sum(rdn<19800101 & rdn>0,na.rm=TRUE),big.mark=","))
samp(dt[rdn>20260622,.(HANDLER_ID,RECEIVE_DATE,SOURCE_TYPE,HANDLER_NAME)],"future_receive_date")
lc <- suppressWarnings(as.integer(dt$HHANDLER_LAST_CHANGE))
rep("HHANDLER_LAST_CHANGE in future: %s ; < RECEIVE_DATE: %s\n\n",
    format(sum(lc>20260622,na.rm=TRUE),big.mark=","),
    format(sum(lc<rdn & !is.na(lc)&!is.na(rdn),na.rm=TRUE),big.mark=","))

cat("================ NAME / PLACEHOLDER ANOMALIES ================\n")
nm <- norm(dt$HANDLER_NAME)
rep("blank HANDLER_NAME: %s\n", format(sum(nm==""),big.mark=","))
ph <- grepl("^(TEST|UNKNOWN|N/?A|NONE|XX+|SAME|DELETE|VOID|DO NOT USE|TBD|PRIVATE)$", nm)
rep("placeholder-looking names (TEST/UNKNOWN/NA/XXX/SAME/...): %s\n", format(sum(ph),big.mark=","))
samp(dt[ph,.(HANDLER_ID,HANDLER_NAME,LOCATION_STATE)],"placeholder_names")
rep("name length 1-2 chars: %s\n", format(sum(nchar(nm)>0 & nchar(nm)<=2),big.mark=","))
# non-ASCII / control chars in name
ctrl <- grepl("[\x01-\x1f]", dt$HANDLER_NAME)
rep("names with control chars: %s\n\n", format(sum(ctrl),big.mark=","))

cat("================ GIS PRIMARY FLAG ================\n")
rep("LOCATION_GIS_PRIMARY values: %s\n",
    paste(capture.output(print(dt[,.N,by=LOCATION_GIS_PRIMARY][order(-N)])), collapse="\n"))
# >1 GIS primary among same coordinate cluster? proxy: same ID multiple coords
multi_coord_id <- g[!is.na(lat)&!is.na(lon), .(ncoord=uniqueN(paste(lat,lon))), by=HANDLER_ID][ncoord>1]
rep("\nHANDLER_IDs with >1 distinct coordinate: %s\n", format(nrow(multi_coord_id),big.mark=","))
samp(merge(dt[,.(HANDLER_ID,LOCATION_LATITUDE,LOCATION_LONGITUDE,SOURCE_TYPE,SEQ_NUMBER,RECEIVE_DATE)],
           head(multi_coord_id,60)[,.(HANDLER_ID)],by="HANDLER_ID")[order(HANDLER_ID)],
     "id_multiple_coords")

cat("\nDone. Flagged samples in", out_dir, "\n")
