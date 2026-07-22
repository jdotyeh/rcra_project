# =============================================================================
# FILE:     00_function.R
# PURPOSE:  Shared functions behind the module master files. Each master script
#           in this folder sources this file; running it on its own only
#           defines the functions.
# INPUTS:   none (sourced by the master scripts 01-07 in this folder)
# OUTPUTS:  none of its own; defines read_module(), recode_pre_date_unknown(),
#           recode_pre_cycle_unknown(), convert_indicators(), and
#           apply_frs_coordinates() with its address and distance helpers
# AUTHOR:   Jason Ye
# CREATED:  2026-07-17
# UPDATED:  2026-07-21
# =============================================================================
#
# Three concerns are shared by every master script and live here, and a fourth
# section holds the FRS coordinate override that the Handler master alone uses.
#
# 1. Reading. read_module() reads a raw RCRAInfo CSV with every column as
#    character, so zero-padded identifiers and yyyymmdd date stamps survive
#    verbatim, and replaces the spaces in the shipped column names with
#    underscores.
#
# 2. Unknown recoding. The ECHO RCRAInfo download summary documents that for
#    several Handler activity flags an "N" recorded before the date the flag
#    entered the notification form does not distinguish "No" from "Unknown".
#    The two recode helpers turn those undistinguishable entries into an
#    explicit "U" (unknown) code so the master files never present them as
#    real negatives:
#      recode_pre_date_unknown()   "N" -> "U" on records whose RECEIVE_DATE
#                                  (yyyymmdd) predates a cutoff, optionally
#                                  restricted to a set of SOURCE_TYPE codes
#      recode_pre_cycle_unknown()  blank -> "U" on records whose REPORT_CYCLE
#                                  predates a cutoff cycle
#    The rules themselves (which fields, which cutoffs) are declared in
#    01_hd_master.R, the one master they apply to.
#
# 3. Indicator conversion. The raw files code binary indicators as Y/N. The
#    master files carry them as 1/0 instead, the usual coding of an economic
#    research dataset. convert_indicators() maps Y -> 1 and N -> 0 on the
#    declared indicator columns and then retypes each: a column whose values
#    are only 1/0 becomes an integer column, while a column that also carries
#    "U" (unknown, from the recodes above or shipped in the raw data) must
#    stay character, holding "1"/"0"/"U".
#
# 4. FRS coordinates. apply_frs_coordinates() replaces a handler record's
#    latitude and longitude with the coordinates the EPA Facility Registry
#    Service holds for the same facility, but only on the records where the two
#    sources can be shown to describe the same place. The rules and their
#    reasoning are documented above the function; 01_hd_master.R is the only
#    caller.
#
# Requires: tidyverse
# =============================================================================

# Load the tidyverse once so each master script does not reload it.
library(tidyverse)

# Read one raw module CSV entirely as character, with underscore column names.
read_module <- function(dir, file) {
  # All columns as character keeps zero-padded IDs and yyyymmdd dates intact.
  df <- read_csv(file.path(dir, file),
                 col_types = cols(.default = "c"), show_col_types = FALSE)
  # Column names arrive with spaces; underscores match how the code uses them.
  names(df) <- gsub(" ", "_", names(df))
  df
}

# "N" -> "U" on the given columns for records whose RECEIVE_DATE predates the
# cutoff (an integer yyyymmdd), optionally restricted to a set of SOURCE_TYPE
# codes. RECEIVE_DATE is always an eight-digit yyyymmdd stamp in the raw data,
# so an integer comparison is exact.
recode_pre_date_unknown <- function(df, cols, cutoff, source_types = NULL) {
  # Parse the yyyymmdd date; unparseable entries become NA and match nothing.
  rd  <- suppressWarnings(as.integer(df$RECEIVE_DATE))
  # Rows whose date sits before the cutoff.
  hit <- !is.na(rd) & rd < cutoff
  # Optionally further restrict to specific SOURCE_TYPE codes.
  if (!is.null(source_types)) hit <- hit & df$SOURCE_TYPE %in% source_types
  # Rewrite "N" to "U" on the hit rows, leaving every other value untouched.
  mutate(df, across(all_of(cols),
                    \(x) if_else(hit & !is.na(x) & x == "N", "U", x)))
}

# blank -> "U" on the given columns for records whose REPORT_CYCLE predates the
# cutoff cycle. Records with no REPORT_CYCLE at all are left untouched: the
# rule speaks only about records that carry a cycle.
recode_pre_cycle_unknown <- function(df, cols, cutoff) {
  # Parse the cycle year; missing cycles fall out of the hit mask entirely.
  rc  <- suppressWarnings(as.integer(df$REPORT_CYCLE))
  hit <- !is.na(rc) & rc < cutoff
  # Rewrite blanks (NA or empty string) to "U" on the hit rows.
  mutate(df, across(all_of(cols),
                    \(x) if_else(hit & (is.na(x) | x == ""), "U", x)))
}

# Y -> "1", N -> "0" on the declared indicator columns, then retype: pure 1/0
# columns become integer; columns that also carry "U" stay character. Any
# value outside Y/N/U in a declared column is a coding surprise worth a hard
# stop rather than a silent pass-through.
convert_indicators <- function(df, cols) {
  # Verify every declared column only ever holds Y/N/U/NA before rewriting.
  bad <- keep(cols, \(cl) !all(df[[cl]] %in% c("Y", "N", "U", NA)))
  if (length(bad)) stop("Non-Y/N/U values in indicator column(s): ",
                        paste(bad, collapse = ", "))
  df |>
    # First pass: Y -> "1", N -> "0"; any "U" or NA passes through unchanged.
    mutate(across(all_of(cols),
                  \(x) case_match(x, "Y" ~ "1", "N" ~ "0", .default = x))) |>
    # Second pass: cast the pure 1/0 columns to integer; leave mixed columns as
    # character so "U" values are not accidentally coerced to NA.
    mutate(across(all_of(cols),
                  \(x) if (all(x %in% c("1", "0", NA))) as.integer(x) else x))
}

# ---- FRS coordinate override (used by the Handler master) -------------------
#
# A handler record carries the coordinates the facility reported on its own
# notification, and many records carry none at all or carry a pair that was
# never corrected. The EPA Facility Registry Service holds one geocoded pair per
# registry identifier, and the Program Links file connects a registry identifier
# to the RCRAInfo Handler ID, so a better pair is available for a large part of
# the file. What the link does not establish is that the two sources describe the
# same place at the same time. A registry identifier follows the facility rather
# than the address, and facilities do move, so importing the FRS pair onto every
# record of every linked handler would silently move a facility's history to
# wherever it sits today.
#
# The override therefore admits a record only when the two sources can be shown
# to agree, under either of two rules, and leaves the reported coordinates alone
# everywhere else.
#
# The address rule reads each record on its own. When the record's street, its
# state, and either its city or the first five digits of its ZIP code match the
# FRS address, the record is at the address FRS geocoded and takes the FRS pair.
# Both addresses are normalised first, because the same address is written
# differently in the two systems: the comparison is case-insensitive, drops all
# punctuation, folds the common street-type and directional words to one
# spelling (STREET and ST, AVENUE and AVE, NORTH and N), and drops the suite,
# unit, and building designators that one side records and the other does not.
# Records of the same handler at a different address are untouched, which is what
# keeps a move from being erased.
#
# The coordinate rule reads the handler as a whole and covers the records whose
# address is written too differently to match. It fires when the handler holds
# only a few distinct coordinate pairs, one of them is the FRS pair, and every
# other pair sits within max_spread_km of it. That pattern is a facility that has
# stayed put and whose records differ only in the precision of what was reported,
# so the whole handler takes the FRS pair. A handler whose pairs are spread wider
# than the threshold, or that carries more than max_variants of them, is one that
# may have moved or may be several places at once, and it keeps what it reported.
#
# The two thresholds and the matching precision are parameters rather than
# constants so they can be moved once the counts each rule produces are read off
# a real run. max_spread_km of one kilometre is a walkable distance around one
# site, and match_digits of four is roughly eleven metres, the precision at which
# two coordinate pairs are the same point.

# Canonical form for the street words the two sources spell differently. The
# names are matched as whole words, so STREET becomes ST but STREETER does not.
addr_abbrev <- c(
  STREET = "ST", AVENUE = "AVE", ROAD = "RD", DRIVE = "DR", BOULEVARD = "BLVD",
  HIGHWAY = "HWY", LANE = "LN", COURT = "CT", CIRCLE = "CIR", PLACE = "PL",
  PARKWAY = "PKWY", TERRACE = "TER", TRAIL = "TRL", SQUARE = "SQ",
  EXPRESSWAY = "EXPY", FREEWAY = "FWY", TURNPIKE = "TPKE", ROUTE = "RTE",
  NORTHEAST = "NE", NORTHWEST = "NW", SOUTHEAST = "SE", SOUTHWEST = "SW",
  NORTH = "N", SOUTH = "S", EAST = "E", WEST = "W",
  SUITE = "STE", APARTMENT = "APT", BUILDING = "BLDG", FLOOR = "FL",
  ROOM = "RM", DEPARTMENT = "DEPT", NUMBER = "NO")

# The same map as whole-word patterns, built once so the normaliser does not
# rebuild it on every call.
addr_abbrev_rx <- setNames(unname(addr_abbrev),
                           paste0("\\b", names(addr_abbrev), "\\b"))

# The designators that name a tenancy inside a site rather than the site. Each
# one is dropped together with the value that follows it, so "100 MAIN ST STE
# 400" and "100 MAIN ST" compare equal.
addr_unit_rx <- "\\b(STE|APT|BLDG|FL|RM|DEPT|UNIT|LOT|SPC|TRLR|NO)\\b\\s*[A-Z0-9-]*"

# Upper case, no punctuation, single spaces. Used for the city and state, where
# nothing beyond that is worth folding.
norm_text <- function(x) {
  x |>
    str_to_upper() |>
    str_replace_all("[^A-Z0-9]+", " ") |>
    str_squish()
}

# The street normaliser: the plain normalisation above, then the abbreviation
# folding and the unit strip. The "#" and whatever follows it goes first, before
# punctuation becomes whitespace, so "#400" does not survive as a bare 400.
norm_address <- function(x) {
  x |>
    str_to_upper() |>
    str_replace_all("#\\s*[A-Z0-9-]*", " ") |>
    norm_text() |>
    str_replace_all(addr_abbrev_rx) |>
    str_remove_all(addr_unit_rx) |>
    str_squish()
}

# Great-circle distance in kilometres between two coordinate pairs.
haversine_km <- function(lat1, lon1, lat2, lon2) {
  # Earth's mean radius in kilometres, and degrees to radians.
  r <- 6371
  p <- pi / 180
  a <- sin((lat2 - lat1) * p / 2)^2 +
    cos(lat1 * p) * cos(lat2 * p) * sin((lon2 - lon1) * p / 2)^2
  # pmin() guards the rounding that can push a into (1, 1 + eps] on identical
  # points, where asin() would return NaN.
  2 * r * asin(pmin(1, sqrt(a)))
}

# A coordinate pair is usable when both halves parse, sit inside their real
# ranges, and are not the (0, 0) placeholder that stands for "not recorded".
valid_coord <- function(lat, lon) {
  !is.na(lat) & !is.na(lon) &
    abs(lat) <= 90 & abs(lon) <= 180 & !(lat == 0 & lon == 0)
}

# Replace LOCATION_LATITUDE and LOCATION_LONGITUDE with the FRS pair on the
# records the two rules above admit, and record which rule admitted each record
# in LOCATION_COORD_SOURCE ("HD" for the records that keep what they reported,
# "FRS_ADDRESS" and "FRS_COORDINATE" for the two rules). The FRS values are
# carried across as the strings FRS publishes, so no rounding is introduced.
apply_frs_coordinates <- function(handler,
                                  facilities_file = "data/frs/FRS_FACILITIES.csv",
                                  links_file      = "data/frs/FRS_PROGRAM_LINKS.csv",
                                  max_variants    = 5L,
                                  max_spread_km   = 1,
                                  match_digits    = 4L) {
  # The address columns, named once: they key the normalisation lookup below.
  addr_cols <- c("LOCATION_STREET_NO", "LOCATION_STREET1", "LOCATION_STREET2",
                 "LOCATION_CITY", "LOCATION_STATE", "LOCATION_ZIP")
  ids <- unique(handler$HANDLER_ID)

  # Handler ID to FRS registry ID, read the same way the panel stage reads it:
  # only the RCRAINFO program rows, only the handlers in hand, only three of the
  # file's columns. A handler that resolves to more than one registry identifier
  # names more than one facility and has no single pair to import, so it is
  # dropped rather than guessed at.
  link <- read_csv(links_file, col_types = cols(.default = "c"),
                   show_col_types = FALSE,
                   col_select = c(PGM_SYS_ACRNM, PGM_SYS_ID, REGISTRY_ID)) |>
    filter(PGM_SYS_ACRNM == "RCRAINFO", PGM_SYS_ID %in% ids) |>
    distinct(HANDLER_ID = PGM_SYS_ID, FRS_ID = REGISTRY_ID) |>
    add_count(HANDLER_ID, name = "n_ids") |>
    filter(n_ids == 1L) |>
    select(-n_ids)

  # The Facilities file's column names come from the ECHO FRS national download
  # (FRS_FACILITIES.csv), and a rename on EPA's side would otherwise surface as
  # an unreadable error from the column selection below. Read the header alone
  # and say which name went missing.
  frs_cols <- c("REGISTRY_ID", "FAC_STREET", "FAC_CITY", "FAC_STATE",
                "FAC_ZIP", "LATITUDE_MEASURE", "LONGITUDE_MEASURE")
  header <- names(read_csv(facilities_file, n_max = 0, show_col_types = FALSE,
                           col_types = cols(.default = "c")))
  missing_cols <- setdiff(frs_cols, header)
  if (length(missing_cols))
    stop("Columns missing from ", facilities_file, ": ",
         paste(missing_cols, collapse = ", "))

  # The FRS facility rows behind those identifiers: the published coordinates,
  # kept both as strings for the write and as numbers for the distance tests,
  # and the normalised address the record-level rule compares against. Rows
  # without a usable pair carry nothing worth importing and drop out here.
  frs <- read_csv(facilities_file, col_types = cols(.default = "c"),
                  show_col_types = FALSE,
                  col_select = c(REGISTRY_ID, FAC_STREET, FAC_CITY,
                                 FAC_STATE, FAC_ZIP, LATITUDE_MEASURE, LONGITUDE_MEASURE)) |>
    filter(REGISTRY_ID %in% link$FRS_ID) |>
    mutate(frs_lat = suppressWarnings(as.numeric(LATITUDE_MEASURE)),
           frs_lon = suppressWarnings(as.numeric(LONGITUDE_MEASURE))) |>
    filter(valid_coord(frs_lat, frs_lon)) |>
    transmute(FRS_ID      = REGISTRY_ID,
              frs_lat, frs_lon,
              frs_lat_chr = LATITUDE_MEASURE,
              frs_lon_chr = LONGITUDE_MEASURE,
              frs_street  = norm_address(FAC_STREET),
              frs_city    = norm_text(FAC_CITY),
              frs_state   = norm_text(FAC_STATE),
              frs_zip     = str_extract(FAC_ZIP, "^[0-9]{5}")) |>
    # A registry identifier that arrives twice with two different pairs cannot
    # settle which is the facility's, so it is dropped for the same reason.
    add_count(FRS_ID, name = "n_rows") |>
    filter(n_rows == 1L) |>
    select(-n_rows)

  # Normalise the addresses on the distinct address tuples rather than on every
  # record; the handler table runs to millions of rows and repeats the same few
  # hundred thousand addresses.
  addr <- handler |>
    distinct(across(all_of(addr_cols))) |>
    mutate(hd_street = norm_address(paste(coalesce(LOCATION_STREET_NO, ""),
                                          coalesce(LOCATION_STREET1, ""),
                                          coalesce(LOCATION_STREET2, ""))),
           hd_city   = norm_text(LOCATION_CITY),
           hd_state  = norm_text(LOCATION_STATE),
           hd_zip    = str_extract(LOCATION_ZIP, "^[0-9]{5}"))

  # One row per handler record, in the handler table's own row order: every
  # right-hand table is unique on its join key, so the joins add columns without
  # adding or reordering rows and the flags below stay aligned with `handler`.
  rows <- handler |>
    select(HANDLER_ID, all_of(addr_cols), LOCATION_LATITUDE, LOCATION_LONGITUDE) |>
    left_join(addr, by = addr_cols) |>
    left_join(link, by = "HANDLER_ID") |>
    left_join(frs,  by = "FRS_ID") |>
    mutate(lat_raw = suppressWarnings(as.numeric(LOCATION_LATITUDE)),
           lon_raw = suppressWarnings(as.numeric(LOCATION_LONGITUDE)),
           # An unusable reported pair is treated as absent, so it neither
           # anchors the handler rule nor widens its spread.
           usable = valid_coord(lat_raw, lon_raw),
           hd_lat = if_else(usable, lat_raw, NA_real_),
           hd_lon = if_else(usable, lon_raw, NA_real_))

  # Address rule: same street, same state, and the same city or the same ZIP
  # code. Comparisons against a missing value return NA, which is not a match.
  addr_hit <- coalesce(
    !is.na(rows$frs_street) & rows$frs_street != "" &
      rows$hd_street == rows$frs_street &
      rows$hd_state == rows$frs_state &
      (rows$hd_city == rows$frs_city |
         coalesce(rows$hd_zip == rows$frs_zip, FALSE)),
    FALSE)

  # Coordinate rule: the handler's distinct reported pairs, rounded to the
  # matching precision, one of which is the FRS pair with the rest close by.
  anchor <- rows |>
    filter(!is.na(hd_lat), !is.na(frs_lat)) |>
    distinct(HANDLER_ID,
             hd_lat = round(hd_lat, match_digits),
             hd_lon = round(hd_lon, match_digits),
             frs_lat, frs_lon) |>
    group_by(HANDLER_ID) |>
    summarise(variants = n(),
              # One reported pair is the FRS pair at the matching precision.
              exact    = any(hd_lat == round(frs_lat, match_digits) &
                               hd_lon == round(frs_lon, match_digits)),
              # The furthest reported pair from the FRS pair, in kilometres.
              spread   = max(haversine_km(hd_lat, hd_lon, frs_lat, frs_lon)),
              .groups  = "drop") |>
    filter(variants <= max_variants, exact, spread <= max_spread_km)

  # A record takes the FRS pair under whichever rule admits it, and the address
  # rule is named first because it is evidence about the record itself rather
  # than about the handler.
  src <- case_when(addr_hit                              ~ "FRS_ADDRESS",
                   rows$HANDLER_ID %in% anchor$HANDLER_ID ~ "FRS_COORDINATE",
                   .default = "HD")

  # Report what the two rules moved, so a run says how much of the file the
  # override actually reaches.
  message("FRS coordinate override: ", sum(src != "HD"), " of ", nrow(handler),
          " handler records (", sum(src == "FRS_ADDRESS"), " by address, ",
          sum(src == "FRS_COORDINATE"), " by coordinate anchor), covering ",
          n_distinct(handler$HANDLER_ID[src != "HD"]), " of ", length(ids),
          " handlers")

  out <- handler |>
    mutate(LOCATION_LATITUDE     = if_else(src == "HD", LOCATION_LATITUDE,
                                           rows$frs_lat_chr),
           LOCATION_LONGITUDE    = if_else(src == "HD", LOCATION_LONGITUDE,
                                           rows$frs_lon_chr),
           LOCATION_COORD_SOURCE = src)

  # The joined copy is as long as the handler table itself; release it before
  # returning so the master build does not carry two of them.
  rm(rows); invisible(gc())
  out
}
