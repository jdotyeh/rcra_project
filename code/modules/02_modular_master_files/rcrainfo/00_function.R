# =============================================================================
# FILE:     00_function.R
# PURPOSE:  Shared functions behind the module master files. Each master script
#           in this folder sources this file; running it on its own only
#           defines the functions.
# INPUTS:   none (sourced by the master scripts 01-07 in this folder)
# OUTPUTS:  none of its own; defines read_module(), recode_pre_date_unknown(),
#           recode_pre_cycle_unknown(), convert_indicators(), read_frs_pairs(),
#           apply_frs_coordinates() with its address and distance helpers,
#           apply_manual_coordinates() with the manual_coords table, and
#           add_coordinate_slots() with coord_slot_cols() and
#           coordinate_review_list()
# AUTHOR:   Jason Ye
# CREATED:  2026-07-17
# UPDATED:  2026-07-22
# =============================================================================
#
# Three concerns are shared by every master script and live here, and four
# further sections hold the coordinate work that the Handler master alone uses.
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
# 4. FRS pairs. read_frs_pairs() resolves each handler to the one pair the EPA
#    Facility Registry Service publishes for it, and says why a handler has no
#    usable pair when it has none. Everything below reads that one table rather
#    than the FRS files themselves, so the national download is read once.
#
# 5. FRS coordinates. apply_frs_coordinates() replaces a handler record's
#    latitude and longitude with the coordinates the EPA Facility Registry
#    Service holds for the same facility, but only on the records where the two
#    sources can be shown to describe the same place. The rules and their
#    reasoning are documented above the function; 01_hd_master.R is the only
#    caller.
#
# 6. Manual coordinates. apply_manual_coordinates() overwrites the coordinates
#    of the few handlers that reach neither FRS rule and hold a pair that is
#    visibly wrong, from the hand-checked manual_coords table above the
#    function. It runs after the FRS override and 01_hd_master.R is again the
#    only caller.
#
# 7. Coordinate slots. add_coordinate_slots() leaves the three columns above
#    alone and adds a second, wider account of the same question, which is every
#    coordinate pair that is available for a record at all, ranked, with the
#    pair that should be used first. coordinate_review_list() then names the
#    facilities for which no pair is available from any source, which are the
#    ones that can only be placed by hand.
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

# The one FRS pair that belongs to each handler, for the handlers given. Returns
# one row per handler that carries at least one RCRAInfo program link, with the
# FRS pair as published (both as strings for a write and as numbers for the
# distance tests), the normalised FRS address the address rule compares against,
# and FRS_STATUS saying whether the pair is usable and, when it is not, why.
#
#   OK                the handler resolves to one registry identifier holding
#                     exactly one facility row with a usable pair
#   MULTI_LINK        the handler resolves to more than one registry identifier,
#                     so it names more than one facility
#   NO_FRS_ROW        the registry identifier is not in the Facilities file
#   FRS_PAIR_INVALID  the identifier's rows are all missing or out of range
#   MULTI_FRS_ROW     the identifier arrives on several rows holding different
#                     usable pairs, so which one is the facility's is unsettled
#
# The pair and address columns are blank on every status other than OK, so a
# caller cannot use an unsettled pair by forgetting to filter. Handlers with no
# link at all are absent from the result entirely, which the callers read as the
# sixth case.
read_frs_pairs <- function(handler_ids,
                           facilities_file = "data/frs/FRS_FACILITIES.csv",
                           links_file      = "data/frs/FRS_PROGRAM_LINKS.csv") {
  # Handler ID to FRS registry ID, read the same way the panel stage reads it:
  # only the RCRAINFO program rows, only the handlers in hand, only three of the
  # file's columns.
  link <- read_csv(links_file, col_types = cols(.default = "c"),
                   show_col_types = FALSE,
                   col_select = c(PGM_SYS_ACRNM, PGM_SYS_ID, REGISTRY_ID)) |>
    filter(PGM_SYS_ACRNM == "RCRAINFO", PGM_SYS_ID %in% handler_ids) |>
    distinct(HANDLER_ID = PGM_SYS_ID, FRS_ID = REGISTRY_ID) |>
    add_count(HANDLER_ID, name = "n_ids")

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

  # The FRS facility rows behind those identifiers, before any test, so that an
  # identifier the file does not hold can be told apart from one whose rows it
  # holds but cannot use.
  raw <- read_csv(facilities_file, col_types = cols(.default = "c"),
                  show_col_types = FALSE, col_select = all_of(frs_cols)) |>
    filter(REGISTRY_ID %in% link$FRS_ID) |>
    mutate(frs_lat = suppressWarnings(as.numeric(LATITUDE_MEASURE)),
           frs_lon = suppressWarnings(as.numeric(LONGITUDE_MEASURE)))
  n_raw <- count(raw, REGISTRY_ID, name = "n_raw")

  # The rows that survive the validity test, counted per identifier so the two
  # remaining failures can be named as well.
  frs <- raw |>
    filter(valid_coord(frs_lat, frs_lon)) |>
    transmute(FRS_ID      = REGISTRY_ID,
              frs_lat, frs_lon,
              frs_lat_chr = LATITUDE_MEASURE,
              frs_lon_chr = LONGITUDE_MEASURE,
              frs_street  = norm_address(FAC_STREET),
              frs_city    = norm_text(FAC_CITY),
              frs_state   = norm_text(FAC_STATE),
              frs_zip     = str_extract(FAC_ZIP, "^[0-9]{5}")) |>
    add_count(FRS_ID, name = "n_valid")
  rm(raw); invisible(gc())

  # A handler with one identifier carries the pair behind it whenever that
  # identifier resolves to exactly one usable facility row.
  single <- link |>
    filter(n_ids == 1L) |>
    select(HANDLER_ID, FRS_ID) |>
    left_join(n_raw, by = c("FRS_ID" = "REGISTRY_ID")) |>
    left_join(distinct(frs, FRS_ID, n_valid), by = "FRS_ID") |>
    mutate(n_raw      = coalesce(n_raw, 0L),
           n_valid    = coalesce(n_valid, 0L),
           FRS_STATUS = case_when(n_raw   == 0L ~ "NO_FRS_ROW",
                                  n_valid == 0L ~ "FRS_PAIR_INVALID",
                                  n_valid  > 1L ~ "MULTI_FRS_ROW",
                                  .default      = "OK")) |>
    select(-n_raw, -n_valid) |>
    left_join(select(filter(frs, n_valid == 1L), -n_valid), by = "FRS_ID")

  # A handler with several identifiers keeps one row naming the failure, so the
  # result stays unique on HANDLER_ID and every caller can join on it directly.
  multi <- link |>
    filter(n_ids > 1L) |>
    distinct(HANDLER_ID) |>
    mutate(FRS_STATUS = "MULTI_LINK")

  out <- bind_rows(single, multi)

  message("FRS pairs: ", sum(out$FRS_STATUS == "OK"), " of ",
          length(handler_ids), " handlers resolve to a usable FRS pair (",
          nrow(out) - sum(out$FRS_STATUS == "OK"), " linked but unusable, ",
          length(handler_ids) - nrow(out), " with no RCRAInfo link)")
  out
}

# Replace LOCATION_LATITUDE and LOCATION_LONGITUDE with the FRS pair on the
# records the two rules above admit, and record which rule admitted each record
# in LOCATION_COORD_SOURCE ("HD" for the records that keep what they reported,
# "FRS_ADDRESS" and "FRS_COORDINATE" for the two rules). The FRS values are
# carried across as the strings FRS publishes, so no rounding is introduced.
apply_frs_coordinates <- function(handler,
                                  frs_pairs     = read_frs_pairs(unique(handler$HANDLER_ID)),
                                  max_variants  = 5L,
                                  max_spread_km = 1,
                                  match_digits  = 4L) {
  # The address columns, named once: they key the normalisation lookup below.
  addr_cols <- c("LOCATION_STREET_NO", "LOCATION_STREET1", "LOCATION_STREET2",
                 "LOCATION_CITY", "LOCATION_STATE", "LOCATION_ZIP")
  ids <- unique(handler$HANDLER_ID)

  # Only the handlers that resolve to one facility with one usable pair have
  # anything to import; read_frs_pairs() has already set the rest aside, and
  # this table is unique on HANDLER_ID, so the join below adds no rows.
  frs <- frs_pairs |>
    filter(FRS_STATUS == "OK") |>
    select(HANDLER_ID, frs_lat, frs_lon, frs_lat_chr, frs_lon_chr,
           frs_street, frs_city, frs_state, frs_zip)

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
    left_join(frs,  by = "HANDLER_ID") |>
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

# ---- Manual coordinate override (used by the Handler master) ----------------
#
# A handful of handlers reach neither FRS rule and are left holding a reported
# pair that is visibly wrong. Where the facility can be identified from its
# address and placed by hand, its coordinates are recorded here rather than left
# to a rule, because no rule reads a value the file never contained. Every entry
# names the source it was read from and the reason the two FRS rules did not
# reach it, so a later reader can retire the entry when the underlying cause is
# fixed. The table is deliberately small and every addition is a documented
# decision; it is not a place to bulk-load geocoding results.
manual_coords <- tribble(
  ~HANDLER_ID,    ~LATITUDE,  ~LONGITUDE,   ~SOURCE,       ~REASON,
  # Baldwin County Electric Membership Cooperative, 41360 County Road 57, Bay
  # Minette, Alabama 36507. Its two coordinate-bearing records report 3050 and
  # -8742, which are degrees and minutes written without a decimal point and so
  # fail the range test, leaving the handler with no usable pair to anchor the
  # coordinate rule. The address rule does not reach it either, because the
  # handler writes a second street line, PINE GROVE ROAD EXTENSION, that FRS
  # does not carry, so the concatenated street never equals the FRS street.
  "ALR000020404", "30.82745", "-87.75000", "Apple Maps", "out-of-range reported pair; second street line blocks the address match")

# Overwrite the coordinates of every record of a handler listed in
# manual_coords, and stamp LOCATION_COORD_SOURCE with "MANUAL". This runs after
# apply_frs_coordinates(), so a manual entry wins over both FRS rules; that is
# intended, since an entry is only made where the rules were checked and found
# not to reach the handler.
apply_manual_coordinates <- function(handler, manual = manual_coords) {
  # A handler named here but absent from the file is a stale entry rather than a
  # harmless no-op, so say so instead of passing over it.
  missing_ids <- setdiff(manual$HANDLER_ID, handler$HANDLER_ID)
  if (length(missing_ids))
    warning("manual_coords names handler(s) absent from the file: ",
            paste(missing_ids, collapse = ", "), call. = FALSE)

  hit <- match(handler$HANDLER_ID, manual$HANDLER_ID)

  message("Manual coordinate override: ", sum(!is.na(hit)), " of ", nrow(handler),
          " handler records across ", n_distinct(manual$HANDLER_ID), " handler(s)")

  handler |>
    mutate(LOCATION_LATITUDE     = if_else(is.na(hit), LOCATION_LATITUDE,
                                           manual$LATITUDE[hit]),
           LOCATION_LONGITUDE    = if_else(is.na(hit), LOCATION_LONGITUDE,
                                           manual$LONGITUDE[hit]),
           LOCATION_COORD_SOURCE = if_else(is.na(hit), LOCATION_COORD_SOURCE,
                                           "MANUAL"))
}

# ---- Coordinate slots (used by the Handler master) --------------------------
#
# The three columns the two overrides above write answer one question, which is
# what the record's own coordinates should be once the evidence that the FRS
# pair belongs to that record has been weighed. The slots answer a different
# one, which is every pair that is available for the record at all, ranked, so
# that a reader who wants the best pair takes the first slot and a reader who
# wants to see what else the file knows reads on. Nothing here overwrites
# LOCATION_LATITUDE, LOCATION_LONGITUDE, or LOCATION_COORD_SOURCE.
#
# The ranking is a preference order over sources rather than a set of admission
# rules, because a slot claims only that a pair exists and says where it came
# from, not that it has been shown to be the record's own.
#
#   1. MANUAL    the hand-checked manual_coords table. It is placed above FRS
#                because every entry was made by locating the facility's own
#                address, which is stronger evidence than a registry link, and
#                because the same precedence already holds between the two
#                overrides above.
#   2. FRS       the pair read from the Facility Registry Service for the
#                handler, whenever read_frs_pairs() settles on one. This is the
#                preferred pair on nearly every record that has one, and it is
#                taken without the address and cluster tests that govern the
#                override, since a slot does not claim the record's address.
#   3. HD        the pair the record itself reports, when it passes the same
#                validity test the FRS pair passes, which is that both halves
#                parse, sit inside their real ranges, and are not the (0, 0)
#                placeholder.
#   4. HD_OTHER  a pair another record of the same handler reports, most
#                frequently reported first and the most recently filed of two
#                equally frequent pairs ahead of the other. These are the
#                alternates that make a facility with a disputed location
#                visible rather than silently resolved.
#
# A pair that repeats a pair already ranked above it does not take a second
# slot, so a handler whose reported pair agrees with FRS carries one slot rather
# than two, and agreement is read off the slot count. Pairs are compared at
# match_digits decimal places, four by default, which is roughly eleven metres
# and the precision at which two pairs are the same point. The values written
# are the strings each source publishes, so no rounding is introduced.
#
# The first slot is named PREFERRED_LATITUDE, PREFERRED_LONGITUDE, and
# PREFERRED_COORD_SOURCE, and the rest are numbered from two. The block is a
# fixed max_slots wide whether or not the data fills it, so the master's columns
# do not move when the input changes; the run message reports the deepest slot
# actually reached, which is what the parameter should be set from.

# The slot column block, in order, for a given number of slots. The master's
# select() names the block through this helper so the two cannot drift apart.
coord_slot_cols <- function(max_slots = 5L) {
  rest <- seq_len(max_slots)[-1]
  c("PREFERRED_LATITUDE", "PREFERRED_LONGITUDE", "PREFERRED_COORD_SOURCE",
    as.vector(rbind(paste0("LATITUDE_",     rest),
                    paste0("LONGITUDE_",    rest),
                    paste0("COORD_SOURCE_", rest))))
}

# Add the slot block to the handler table. Call this before
# apply_frs_coordinates(), while LOCATION_LATITUDE and LOCATION_LONGITUDE still
# hold what the facility reported, so that the HD slot is the reported pair
# rather than one an override has already replaced.
add_coordinate_slots <- function(handler,
                                 frs_pairs    = read_frs_pairs(unique(handler$HANDLER_ID)),
                                 manual       = manual_coords,
                                 max_slots    = 5L,
                                 match_digits = 4L) {
  # The pair each record reports, parsed once, with the rounded form the
  # duplicate test compares on. An unusable pair is treated as absent.
  rec <- handler |>
    select(HANDLER_ID, RECEIVE_DATE, LOCATION_LATITUDE, LOCATION_LONGITUDE) |>
    mutate(rd    = suppressWarnings(as.integer(RECEIVE_DATE)),
           lat   = suppressWarnings(as.numeric(LOCATION_LATITUDE)),
           lon   = suppressWarnings(as.numeric(LOCATION_LONGITUDE)),
           ok    = valid_coord(lat, lon),
           lat_r = if_else(ok, round(lat, match_digits), NA_real_),
           lon_r = if_else(ok, round(lon, match_digits), NA_real_))

  # Every distinct pair a handler reports anywhere in the file, with the number
  # of records behind it and the most recently filed spelling of it, which is
  # the spelling the alternate slots carry.
  hd_pairs <- rec |>
    filter(ok) |>
    group_by(HANDLER_ID, lat_r, lon_r) |>
    summarise(n_records = n(),
              last_rd   = max(coalesce(rd, 0L)),
              i         = which.max(coalesce(rd, 0L)),
              lat_chr   = LOCATION_LATITUDE[i],
              lon_chr   = LOCATION_LONGITUDE[i],
              .groups   = "drop")

  # The alternates a handler offers, in the order they take their slots. The cap
  # is applied here as well as at the end, so a handler that reports hundreds of
  # pairs does not carry hundreds of candidate rows through the join below.
  hd_alt <- hd_pairs |>
    arrange(HANDLER_ID, desc(n_records), desc(last_rd), lat_r, lon_r) |>
    group_by(HANDLER_ID) |>
    mutate(ord = row_number()) |>
    ungroup() |>
    filter(ord <= max_slots) |>
    select(HANDLER_ID, ord,
           cand_lat_r = lat_r, cand_lon_r = lon_r,
           cand_lat_chr = lat_chr, cand_lon_chr = lon_chr)

  # A record's slots depend on its handler and on its own spelling of its pair
  # and on nothing else it carries, so the block is built on the distinct
  # combinations of the two and joined back to the records afterwards. The
  # handler table runs to millions of rows and repeats far fewer pairs.
  key <- distinct(rec, HANDLER_ID, LOCATION_LATITUDE, LOCATION_LONGITUDE,
                  lat_r, lon_r)

  # The hand-placed pair and the FRS pair, each already one per handler.
  manual_c <- manual |>
    transmute(HANDLER_ID,
              cand_lat_chr = LATITUDE, cand_lon_chr = LONGITUDE,
              cand_lat_r   = round(suppressWarnings(as.numeric(LATITUDE)),
                                   match_digits),
              cand_lon_r   = round(suppressWarnings(as.numeric(LONGITUDE)),
                                   match_digits),
              COORD_SOURCE = "MANUAL", rank = 1L, ord = 0L)

  frs_c <- frs_pairs |>
    filter(FRS_STATUS == "OK") |>
    transmute(HANDLER_ID,
              cand_lat_chr = frs_lat_chr, cand_lon_chr = frs_lon_chr,
              cand_lat_r   = round(frs_lat, match_digits),
              cand_lon_r   = round(frs_lon, match_digits),
              COORD_SOURCE = "FRS", rank = 2L, ord = 0L)

  # One row per candidate pair per distinct combination, the four sources
  # stacked in their ranked order.
  cand <- bind_rows(
    inner_join(key, manual_c, by = "HANDLER_ID"),
    inner_join(key, frs_c,    by = "HANDLER_ID"),
    key |>
      filter(!is.na(lat_r)) |>
      mutate(cand_lat_chr = LOCATION_LATITUDE, cand_lon_chr = LOCATION_LONGITUDE,
             cand_lat_r   = lat_r,             cand_lon_r   = lon_r,
             COORD_SOURCE = "HD", rank = 3L, ord = 0L),
    inner_join(key, hd_alt, by = "HANDLER_ID", relationship = "many-to-many") |>
      mutate(COORD_SOURCE = "HD_OTHER", rank = 4L))

  # Rank order first, then drop a pair that repeats one already taken, which
  # distinct() does by keeping the first row of each rounded pair in the order
  # just set. What survives is numbered, and the numbering is the slot.
  slots <- cand |>
    arrange(HANDLER_ID, LOCATION_LATITUDE, LOCATION_LONGITUDE, rank, ord) |>
    distinct(HANDLER_ID, LOCATION_LATITUDE, LOCATION_LONGITUDE,
             cand_lat_r, cand_lon_r, .keep_all = TRUE) |>
    group_by(HANDLER_ID, LOCATION_LATITUDE, LOCATION_LONGITUDE) |>
    mutate(slot = row_number()) |>
    ungroup()

  # How deep the data actually goes, read before the cap is applied, so the
  # message can say what max_slots is cutting off.
  deepest <- max(slots$slot)

  wide <- slots |>
    filter(slot <= max_slots) |>
    select(HANDLER_ID, LOCATION_LATITUDE, LOCATION_LONGITUDE, slot,
           LATITUDE = cand_lat_chr, LONGITUDE = cand_lon_chr, COORD_SOURCE) |>
    pivot_wider(id_cols     = c(HANDLER_ID, LOCATION_LATITUDE, LOCATION_LONGITUDE),
                names_from  = slot,
                values_from = c(LATITUDE, LONGITUDE, COORD_SOURCE),
                names_glue  = "{.value}_{slot}") |>
    rename(PREFERRED_LATITUDE     = LATITUDE_1,
           PREFERRED_LONGITUDE    = LONGITUDE_1,
           PREFERRED_COORD_SOURCE = COORD_SOURCE_1)

  # Give the block its full width even where the data does not reach it, so the
  # master's columns are the same on every run.
  want    <- coord_slot_cols(max_slots)
  unfilled <- setdiff(want, names(wide))
  if (length(unfilled)) wide[unfilled] <- NA_character_
  wide <- select(wide, HANDLER_ID, LOCATION_LATITUDE, LOCATION_LONGITUDE,
                 all_of(want))

  # Every right-hand row is one combination of the three join columns and the
  # records repeat those combinations, so the join adds columns without adding
  # rows, which the relationship argument holds the join to. Missing coordinates
  # match missing coordinates, which is dplyr's default and is what puts the FRS
  # pair on a record that reported nothing.
  out <- left_join(handler, wide,
                   by = c("HANDLER_ID", "LOCATION_LATITUDE", "LOCATION_LONGITUDE"),
                   relationship = "many-to-one")

  filled <- !is.na(out$PREFERRED_COORD_SOURCE)
  message("Coordinate slots: ", sum(filled), " of ", nrow(out),
          " handler records carry a preferred pair (",
          paste(names(table(out$PREFERRED_COORD_SOURCE)),
                table(out$PREFERRED_COORD_SOURCE), collapse = ", "),
          "); ", n_distinct(out$HANDLER_ID[!filled]),
          " handlers have no pair from any source; deepest slot reached is ",
          deepest, " against a max_slots of ", max_slots)

  # The candidate tables are built on the distinct combinations rather than on
  # the records, but the joined copy is as long as the handler table itself;
  # release everything before returning.
  rm(rec, hd_pairs, hd_alt, key, cand, slots, wide); invisible(gc())
  out
}

# The facilities that no source can place, which are the ones a person has to
# find by hand. A handler qualifies when none of its records carries a preferred
# pair, so it has no manual entry, no usable FRS pair, and no usable reported
# pair on any of its records. Call this after add_coordinate_slots() and before
# the dimension joins, while the table is still one row per source record.
#
# Each row carries the handler's latest name and address, which is what a person
# would search on, together with why the two automatic sources failed:
# FRS_STATUS is the code read_frs_pairs() assigned, "NO_LINK" where the handler
# has no RCRAInfo program link at all, and HD_COORD_STATUS separates a handler
# that reported no coordinates from one whose reported coordinates failed the
# validity test, which is the case worth reading, since a pair that fails the
# test is often a real location written in the wrong units.
#
# ids restricts the list to a set of handlers, which is how a caller asks only
# about the facilities a panel actually uses rather than the whole file.
coordinate_review_list <- function(handler, frs_pairs, ids = NULL) {
  need <- handler |>
    group_by(HANDLER_ID) |>
    summarise(has_pref = any(!is.na(PREFERRED_COORD_SOURCE)), .groups = "drop") |>
    filter(!has_pref) |>
    pull(HANDLER_ID)
  if (!is.null(ids)) need <- intersect(need, ids)

  handler |>
    filter(HANDLER_ID %in% need) |>
    mutate(rd       = suppressWarnings(as.integer(RECEIVE_DATE)),
           reported = !is.na(LOCATION_LATITUDE) | !is.na(LOCATION_LONGITUDE)) |>
    group_by(HANDLER_ID) |>
    # The latest record is the one to search on, and the latest record that
    # reported anything is the one whose failed pair is worth showing; where
    # nothing was ever reported the second index lands on a row holding
    # nothing, which is the right answer.
    summarise(i = which.max(coalesce(rd, 0L)),
              j = which.max(coalesce(rd, 0L) * reported),
              HD_NAME    = HANDLER_NAME[i],
              HD_STREET  = str_squish(paste(coalesce(LOCATION_STREET_NO[i], ""),
                                            coalesce(LOCATION_STREET1[i], ""),
                                            coalesce(LOCATION_STREET2[i], ""))),
              HD_CITY    = LOCATION_CITY[i],
              HD_STATE   = LOCATION_STATE[i],
              HD_ZIP     = LOCATION_ZIP[i],
              HD_COUNTY_CODE      = COUNTY_CODE[i],
              HD_RECORDS          = n(),
              LATEST_RECEIVE_DATE = RECEIVE_DATE[i],
              RECORDS_WITH_REPORTED_PAIR = sum(reported),
              REPORTED_LATITUDE   = LOCATION_LATITUDE[j],
              REPORTED_LONGITUDE  = LOCATION_LONGITUDE[j],
              .groups = "drop") |>
    select(-i, -j) |>
    left_join(select(frs_pairs, HANDLER_ID, FRS_STATUS), by = "HANDLER_ID") |>
    mutate(FRS_STATUS      = coalesce(FRS_STATUS, "NO_LINK"),
           HD_COORD_STATUS = if_else(RECORDS_WITH_REPORTED_PAIR == 0L,
                                     "NONE_REPORTED", "REPORTED_INVALID")) |>
    select(HANDLER_ID, HD_NAME, HD_STREET, HD_CITY, HD_STATE, HD_ZIP,
           HD_COUNTY_CODE, HD_RECORDS, LATEST_RECEIVE_DATE,
           FRS_STATUS, HD_COORD_STATUS, RECORDS_WITH_REPORTED_PAIR,
           REPORTED_LATITUDE, REPORTED_LONGITUDE) |>
    arrange(HD_STATE, HANDLER_ID)
}
