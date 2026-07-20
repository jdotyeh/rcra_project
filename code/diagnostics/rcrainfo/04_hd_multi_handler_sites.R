# 04_hd_multi_handler_sites.R
# -----------------------------------------------------------------------------
# Goal: From HD_REPORTING, find physical facilities that share the SAME facility
# name and the SAME coordinates (latitude + longitude) but appear as MULTIPLE
# distinct handler registrations (HANDLER IDs) -- e.g. "CHEVRON RICHMOND REFINERY"
# at 37.93134 / -122.390926 registered under several owners.
#
# Such groups are "big" facilities: one physical site carrying 2+ separate
# RCRA handler records that differ in owner/operator/etc.
#
# Output: a CSV with every row belonging to one of these multi-handler groups,
# plus a printed count of how many such "big" facilities exist.
# -----------------------------------------------------------------------------

suppressPackageStartupMessages(library(data.table))

in_file <- "data/rcrainfo/hd/HD_REPORTING.csv"
out_csv <- "output/diagnostics/HD_REPORTING_multi_handler_facilities.csv"
dir.create(dirname(out_csv), showWarnings = FALSE, recursive = TRUE)

# Read all rows (all columns kept as character to preserve the raw values
# exactly for the output file).
message("Reading ", in_file, " ...")
dt <- fread(in_file, colClasses = "character", showProgress = FALSE)
message("Total rows read: ", format(nrow(dt), big.mark = ","))

# --- Build the grouping key: facility name + coordinates -----------------------
# Normalize name (trim + upper) and coordinates (trim) so trivial formatting
# differences don't split a genuine match. Require non-missing coordinates --
# rows without coordinates can't be matched on location.
dt[, .name := toupper(trimws(`HANDLER NAME`))]
dt[, .lat  := trimws(`LOCATION LATITUDE`)]
dt[, .lon  := trimws(`LOCATION LONGITUDE`)]

has_coords <- dt$.lat != "" & dt$.lon != "" & !is.na(dt$.lat) & !is.na(dt$.lon)
dt_geo <- dt[has_coords & .name != ""]
message("Rows with usable name + coordinates: ",
        format(nrow(dt_geo), big.mark = ","))

# A "case" is one (name, lat, lon) group. It is a multi-handler / "big" facility
# when it contains MORE THAN ONE distinct HANDLER ID -- i.e. several separate
# registrations at the same physical site.
dt_geo[, n_handlers := uniqueN(`HANDLER ID`), by = .(.name, .lat, .lon)]

multi <- dt_geo[n_handlers > 1]

# Group-level summary (one row per big facility).
groups <- multi[, .(
  n_distinct_handler_ids = uniqueN(`HANDLER ID`),
  n_rows                 = .N
), by = .(facility_name = .name, latitude = .lat, longitude = .lon)][
  order(-n_distinct_handler_ids, facility_name)]

# --- Write output --------------------------------------------------------------
# Drop helper columns, keep all original columns, sorted so grouped rows sit
# together.
out <- copy(multi)
setorder(out, .name, .lat, .lon, `HANDLER ID`, `SEQ NUMBER`)
out[, c(".name", ".lat", ".lon", "n_handlers") := NULL]
fwrite(out, out_csv)

# --- Report --------------------------------------------------------------------
cat("\n===========================================================\n")
cat("Multi-handler ('big') facilities -- same name & coordinates\n")
cat("===========================================================\n")
cat("Number of 'big' facilities (distinct name+coord groups w/ 2+ handler IDs): ",
    format(nrow(groups), big.mark = ","), "\n", sep = "")
cat("Total rows written to ", out_csv, ": ",
    format(nrow(out), big.mark = ","), "\n", sep = "")

cat("\nDistribution -- how many distinct handler IDs per big facility:\n")
print(groups[, .(n_facilities = .N), by = n_distinct_handler_ids][order(n_distinct_handler_ids)])

cat("\nTop 15 biggest facilities by number of distinct handler IDs:\n")
print(head(groups, 15))
