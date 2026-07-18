# =============================================================================
# FILE:     00_panel_functions.R
# PURPOSE:  Shared functions behind the facility panels. The panel scripts in
#           this folder source this file and call these functions; running it on
#           its own only defines them. Generic helpers (FRS link, value joins,
#           panel writer) serve every panel; the Biennial Report machinery
#           builds the balanced and unbalanced facility-cycle panels.
# INPUTS:   none (sourced by the panel scripts in this folder)
# OUTPUTS:  none of its own; defines read_frs_links(), join_distinct(),
#           last_known(), write_panel(), and build_br_panel() with its helpers
# AUTHOR:   Jason Ye
# CREATED:  2026-07-16
# UPDATED:  2026-07-16
# =============================================================================
#
# Requires: tidyverse (incl. lubridate)

library(tidyverse)

# ---- Generic helpers (used by every panel) ----------------------------------

# Link handlers to their FRS REGISTRY_ID through the FRS Program Links file,
# matching the RCRAInfo Handler ID against PGM_SYS_ID on the RCRAINFO program
# rows. RCRAINFO PGM_SYS_ID -> REGISTRY_ID is 1:1, so this stays one row per
# handler and the downstream join does not fan out the panel.
read_frs_links <- function(ids, frs_file = "data/frs/FRS_PROGRAM_LINKS.csv") {
  read_csv(frs_file, col_types = cols(.default = "c"), show_col_types = FALSE,
           col_select = c(PGM_SYS_ACRNM, PGM_SYS_ID, REGISTRY_ID)) |>
    filter(PGM_SYS_ACRNM == "RCRAINFO", PGM_SYS_ID %in% ids) |>
    distinct(HANDLER_ID = PGM_SYS_ID, FRS_ID = REGISTRY_ID)
}

# Distinct non-missing values in order of appearance, ";"-joined ("" if none).
join_distinct <- function(x) {
  x <- x[!is.na(x) & x != ""]
  if (length(x)) paste(unique(x), collapse = ";") else ""
}

# Last non-missing value (used for the most-recent handler snapshot), else NA.
last_known <- function(x) {
  x <- x[!is.na(x)]
  if (length(x)) x[length(x)] else NA_character_
}

# Write a panel: create the folder, write the CSV, and optionally an .rds twin.
# Plain CSV stores no column types, so read_csv() re-guesses them from the first
# rows and mistypes sparse columns (a mostly-empty column reads as all-NA
# logical; "05" region codes lose the leading zero). The .rds copy preserves
# every column's type exactly; load it with read_rds().
write_panel <- function(out, out_file, rds = FALSE) {
  dir.create(dirname(out_file), showWarnings = FALSE, recursive = TRUE)
  write_csv(out, out_file, na = "")
  if (rds) write_rds(out, sub("\\.csv$", ".rds", out_file), compress = "gz")
  invisible(out)
}

# ---- Biennial Report facility-cycle panel machinery --------------------------
#
# build_br_panel() builds the LQG/TSDF facility-cycle panels; balanced = TRUE
# keeps only handlers recognized in ALL cycles, balanced = FALSE keeps every
# handler in the cycles where it qualifies. The column definitions and the
# conflict-resolution design are documented in the two build scripts
# (01_panel_2015_2023_balanced.R, 02_panel_2015_2023_unbalanced.R).
#
# Conflict resolution (one design, three tiers). Timelines are built per
# HANDLER_ID across all source records; records sharing a RECEIVE_DATE collapse
# to ONE value before the timeline, and the rule that picks it depends on the
# variable:
#   1. FED_WASTE_GENERATOR  most-severe wins on the day (gen_sev), and any
#                           facility-year still flagged in HD_CONFLICTS is then
#                           overridden by BR_GENERATOR -- the Biennial Report is
#                           authoritative for the federal generator status.
#   2. 1/0 indicators       higher status wins: 1 > 0 > U (tsd_sev for
#                           TSD_ACTIVITY; ind_sev for the batch attrs). The
#                           masters code these flags 1/0, with "U" for entries
#                           whose "N" predates the flag (see the
#                           02_modular_master_files README); unknown never
#                           beats a real value.
#   3. STATE_WASTE_GENERATOR state code mapped to the federal hierarchy
#                           (L=1 > S=2 > VS=3 > N, state_sev) and the higher
#                           status wins; codes with no federal mapping rank
#                           below everything.
# HD_CONFLICTS still lists every same-year disagreement (audit trail): a listed
# field means the inputs disagreed, not that the resolved value is in doubt.

# Recode + severity (higher = more severe) for the HD_MASTER status timelines.
gen_sev    <- c(L = 5L, S = 4L, VS = 3L, N = 2L, P = 1L, U = 0L)
tsd_sev    <- c(`1` = 2L, `0` = 1L, U = 0L)
# The master-file 1/0/U activity indicators, ranked 1 > 0 > U.
ind_sev    <- c(`1` = 2L, `0` = 1L, U = 0L)
# State generator resolved on the FEDERAL hierarchy: convert the state code
# (L=1 > S=2 > VS=3 > N), numerics already federal. Codes outside this set have
# no federal mapping -> severity -1 via coalesce, so they never beat a
# convertible code (see "Conflict resolution" above).
state_sev  <- c(L = 3L, `1` = 3L, S = 2L, `2` = 2L, VS = 1L, `3` = 1L, N = 0L)
recode_gen <- c(`1` = "L", `2` = "S", `3` = "VS", N = "N", P = "P", U = "U")
tons_cols  <- c("BR_GENERATE_TONS", "BR_MANAGE_TONS", "BR_SHIP_TONS", "BR_RECEIVE_TONS")

# HD_MASTER source column -> panel name for the duration-dominant attributes
# (HD_GENERATOR / HD_TSDF are handled separately, with recode + severity ties).
hd_attr_map <- c(
  ACTIVITY_LOCATION              = "HD_ACTIVITY_STATE",
  LOCATION_STATE                 = "HD_LOCATION_STATE",
  COUNTY_CODE                    = "HD_LOCATION_COUNTY",
  REGION                         = "HD_EPA_REGION",
  LOCATION_LATITUDE              = "HD_LOCATION_LATITUDE",
  LOCATION_LONGITUDE             = "HD_LOCATION_LONGITUDE",
  SHORT_TERM_GENERATOR           = "HD_SHORT_TERM_GENERATOR",
  RECYCLER_ACTIVITY              = "HD_RECYCLER_STORAGE",
  RECYCLER_ACTIVITY_NONSTORAGE   = "HD_RECYCLER_NONSTORAGE",
  IMPORTER_ACTIVITY              = "HD_IMPORTER",
  RECOGNIZED_TRADER_IMPORTER     = "HD_RECOGNIZED_TRADER_IMPORTER",
  RECOGNIZED_TRADER_EXPORTER     = "HD_RECOGNIZED_TRADER_EXPORTER",
  SLAB_IMPORTER                  = "HD_SLAB_IMPORTER",
  SLAB_EXPORTER                  = "HD_SLAB_EXPORTER",
  TRANSPORTER                    = "HD_TRANSPORTER",
  TRANSFER_FACILITY              = "HD_TRANSFER_FACILITY",
  ONSITE_BURNER_EXEMPTION        = "HD_ONSITE_BURNER_EXEMPTION",
  FURNACE_EXEMPTION              = "HD_FURNACE_EXEMPTION",
  UNDERGROUND_INJECTION_ACTIVITY = "HD_UNDERGROUND_INJECTION_ACTIVITY",
  OFF_SITE_RECEIPT               = "HD_OFF_SITE_RECEIPT",
  LQHUW                          = "HD_UNIVERSAL_WASTE_LQ_HANDLER",
  UNIVERSAL_WASTE_DEST_FACILITY  = "HD_UNIVERSAL_WASTE_DEST_FACILITY",
  USED_OIL_TRANSPORTER           = "HD_USED_OIL_TRANSPORTER",
  USED_OIL_TRANSFER_FACILITY     = "HD_USED_OIL_TRANSFER_FACILITY",
  USED_OIL_PROCESSOR             = "HD_USED_OIL_PROCESSOR",
  USED_OIL_REFINER               = "HD_USED_OIL_REFINER",
  USED_OIL_BURNER                = "HD_USED_OIL_BURNER",
  USED_OIL_MARKET_BURNER         = "HD_USED_OIL_MARKET_BURNER",
  USED_OIL_SPEC_MARKETER         = "HD_USED_OIL_SPEC_MARKETER")

# Every HD_* status/attribute column eligible for the HD_CONFLICTS string,
# source -> panel name (adds state generator + the recoded generator + TSDF,
# which are resolved by their own dominant() calls, to the batch attr set).
hd_all_map <- c(hd_attr_map,
                STATE_WASTE_GENERATOR = "HD_STATE_GENERATOR",
                FED_WASTE_GENERATOR   = "HD_GENERATOR",
                TSD_ACTIVITY          = "HD_TSDF")

# Final HD_* block order in the written panel (after the BR_* columns).
hd_order <- c(
  "HD_ACTIVITY_STATE", "HD_LOCATION_STATE", "HD_LOCATION_COUNTY", "HD_EPA_REGION",
  "HD_LOCATION_LATITUDE", "HD_LOCATION_LONGITUDE",
  "NAICS4", "NAICS6_1", "NAICS6_2", "NAICS6_3", "NAICS6_4", "HD_RECORD_COUNT",
  "HD_GENERATOR", "HD_STATE_GENERATOR", "HD_SHORT_TERM_GENERATOR",
  "HD_TSDF", "HD_RECYCLER_STORAGE", "HD_RECYCLER_NONSTORAGE",
  "HD_IMPORTER", "HD_RECOGNIZED_TRADER_IMPORTER", "HD_RECOGNIZED_TRADER_EXPORTER",
  "HD_SLAB_IMPORTER", "HD_SLAB_EXPORTER",
  "HD_TRANSPORTER", "HD_TRANSFER_FACILITY",
  "HD_ONSITE_BURNER_EXEMPTION", "HD_FURNACE_EXEMPTION",
  "HD_UNDERGROUND_INJECTION_ACTIVITY", "HD_OFF_SITE_RECEIPT",
  "HD_UNIVERSAL_WASTE_LQ_HANDLER", "HD_UNIVERSAL_WASTE_DEST_FACILITY",
  "HD_USED_OIL_TRANSPORTER", "HD_USED_OIL_TRANSFER_FACILITY", "HD_USED_OIL_PROCESSOR",
  "HD_USED_OIL_REFINER", "HD_USED_OIL_BURNER", "HD_USED_OIL_MARKET_BURNER",
  "HD_USED_OIL_SPEC_MARKETER")

# One Biennial Report cycle: LQG/TSDF membership flags + facility-year tonnage
# sums, one row per qualifying handler; a single read of BR_REPORTING serves
# both the membership flags and the tonnage sums.
br_one_cycle <- function(year, br_dir) {
  br <- read_csv(file.path(br_dir, sprintf("BR_REPORTING_%d.csv", year)),
                 col_types = cols(.default = "c"), show_col_types = FALSE,
                 col_select = c(`HANDLER ID`, `CALCULATED GENERATOR STATUS`,
                                `MGMT ID INCLUDED IN NBR`, `RECV ID INCLUDED IN NBR`,
                                `GENERATION TONS`, `MANAGED TONS`,
                                `SHIPPED TONS`, `RECEIVED TONS`,
                                `GEN WASTE INCLUDED IN NBR`, `MGMT WASTE INCLUDED IN NBR`,
                                `SHIP WASTE INCLUDED IN NBR`, `RECV WASTE INCLUDED IN NBR`))
  names(br) <- gsub(" ", "_", names(br))

  # The raw BR flags stay Y/N-coded (only the master files recode indicators),
  # so the tests here read the raw codes; BR_TSDF leaves as a 1/0 indicator.
  br |>
    mutate(across(ends_with("_TONS"), as.numeric)) |>
    group_by(HANDLER_ID) |>
    summarise(
      BR_GENERATOR = if_else(any(CALCULATED_GENERATOR_STATUS == "L", na.rm = TRUE), "L", "N"),
      BR_TSDF      = if_else(any(MGMT_ID_INCLUDED_IN_NBR == "Y" |
                                   RECV_ID_INCLUDED_IN_NBR == "Y", na.rm = TRUE), 1L, 0L),
      BR_GENERATE_TONS = sum(GENERATION_TONS[GEN_WASTE_INCLUDED_IN_NBR == "Y"], na.rm = TRUE),
      BR_MANAGE_TONS   = sum(MANAGED_TONS[MGMT_WASTE_INCLUDED_IN_NBR == "Y"],    na.rm = TRUE),
      BR_SHIP_TONS     = sum(SHIPPED_TONS[SHIP_WASTE_INCLUDED_IN_NBR == "Y"],    na.rm = TRUE),
      BR_RECEIVE_TONS  = sum(RECEIVED_TONS[RECV_WASTE_INCLUDED_IN_NBR == "Y"],   na.rm = TRUE),
      .groups = "drop") |>
    filter(BR_GENERATOR == "L" | BR_TSDF == 1L) |>
    mutate(REPORT_CYCLE = as.character(year))
}

# Membership across cycles. Balanced keeps only handlers recognized in ALL
# cycles (n rows per handler); unbalanced keeps a row for every cycle in which
# the handler qualifies (1 to n rows per handler, a strict superset).
br_membership <- function(cycles, br_dir, balanced) {
  panel <- map(cycles, br_one_cycle, br_dir = br_dir) |> list_rbind()
  if (balanced) {
    panel <- panel |>
      group_by(HANDLER_ID) |>
      filter(n_distinct(REPORT_CYCLE) == length(cycles)) |>
      ungroup()
  }
  panel
}

# Handler-master source records for the panel handlers, with the classification
# year (RY) that buckets records for HD_RECORD_COUNT and HD_CONFLICTS.
# Biennial-Report-fed source types (B, R) describe a report cycle, not the
# submission date: their filings arrive mostly in the even year AFTER the odd
# cycle year, so they are classified by REPORT_CYCLE (kept when it is a sane
# 1980-2026 year). B/R records with no usable cycle fall back to the receive
# year, stepped down to the preceding odd year when even. All other source
# types classify by receive year.
read_hd_records <- function(hd_file, ids) {
  read_csv(hd_file, col_types = cols(.default = "c"), show_col_types = FALSE,
           col_select = c(HANDLER_ID, SOURCE_TYPE, SEQ_NUMBER, NAICS_SEQ,
                          NAICS_CODE, RECEIVE_DATE, REPORT_CYCLE, all_of(names(hd_all_map)))) |>
    filter(HANDLER_ID %in% ids) |>
    distinct() |>
    mutate(date     = ymd(RECEIVE_DATE),
           rcv_year = year(date),
           rc       = suppressWarnings(as.integer(REPORT_CYCLE)),
           RY = case_when(
             SOURCE_TYPE %in% c("B", "R") & !is.na(rc) &
               rc >= 1980L & rc <= 2026L                 ~ rc,
             SOURCE_TYPE %in% c("B", "R") & !is.na(rcv_year) &
               rcv_year %% 2L == 0L                      ~ rcv_year - 1L,
             .default = rcv_year))
}

# HD_CONFLICTS: for each facility-year, panel names of the HD_* fields carrying
# >= 2 distinct values CLASSIFIED to that report year (RY), ";"-joined in schema
# (hd_order) order. Rows with no conflict are absent here (written as "").
hd_conflicts <- function(rec) {
  rec |>
    filter(!is.na(RY)) |>
    select(HANDLER_ID, RY, all_of(names(hd_all_map))) |>
    pivot_longer(all_of(names(hd_all_map)), names_to = "src", values_to = "val") |>
    filter(!is.na(val), val != "") |>
    group_by(HANDLER_ID, REPORT_CYCLE = as.character(RY), src) |>
    summarise(conf = n_distinct(val) > 1, .groups = "drop") |>
    filter(conf) |>
    mutate(field = unname(hd_all_map[src])) |>
    group_by(HANDLER_ID, REPORT_CYCLE) |>
    arrange(match(field, hd_order), .by_group = TRUE) |>
    summarise(HD_CONFLICTS = paste(field, collapse = ";"), .groups = "drop")
}

# HD_RECORD_COUNT: source records (distinct SOURCE_TYPE x SEQ_NUMBER) classified
# to the report year (RY), pooled across all source types.
hd_record_count <- function(rec) {
  rec |>
    filter(!is.na(RY)) |>
    distinct(HANDLER_ID, RY, SOURCE_TYPE, SEQ_NUMBER) |>
    count(HANDLER_ID, REPORT_CYCLE = as.character(RY), name = "HD_RECORD_COUNT")
}

# NAICS4 / NAICS6_1-4: facility-year industry codes. Five columns per
# facility-year from the FULL NAICS_SEQ listing (rule decided 2026-07-10).
# NAICS is not a conflict variable -- multiple codes on one record are a
# feature of the notification form -- so it sits outside hd_attr_map and
# HD_CONFLICTS. Years here are calendar years of RECEIVE_DATE (the rule
# predates and does not use the B/R cycle reclassification above).
#
# Normalize -> validate each raw code:
#   - optional-zero codes always get the trailing 0 (33791 -> 337910; 573 base
#     codes in NDV_HANDLER_NAICS_optional_zero_codes.txt);
#   - retired 517110 crosswalks to 517111 (Census 2017->2022 concordance);
#   - 6-digit codes must appear in NDV_HANDLER_NAICS_CODES.md -- harvested from
#     the FULL line of every row because ~54 codes + 3 sector ranges sit
#     glitch-embedded in description text -- or in the 11-code whitelist of
#     NAICS-2022 codes the scrape lacks; other 6-digit codes are invalid;
#   - shorter codes and the sector ranges (31-33/44-45/48-49) are kept as-is:
#     73% of facility-years carrying one have no other code, so dropping them
#     would blank the facility-year. NAICS4 stays NA when the winning code has
#     fewer than four leading digits.
# Within a year, a submission is a distinct RECEIVE_DATE carrying >= 1 valid
# code (dates whose codes are all invalid open no window); its duration runs
# to the next submission that year, the last to Dec 31; windows never cross
# years.
#   NAICS6_1-4  codes ordered by NAICS_SEQ asc, submission duration desc,
#               latest RECEIVE_DATE, highest SEQ_NUMBER (exact ties), then
#               deduplicated keep-first; the first four fill the slots.
#   NAICS4      first four digits of the lowest-seq code on the winner
#               submission (longest duration, tie -> latest date).
# Year assignment: >= 1 valid code received in the year -> that year only (no
# backfill). Records received but none valid -> all five NA, no carry. No
# records received in the year -> carry all five from the nearest earlier
# year (>= 1980) with a valid code; nothing earlier -> blank.
naics_facility_year <- function(rec, panel,
                                oz_file = "data/rcrainfo/hd/NDV_HANDLER_NAICS_optional_zero_codes.txt",
                                md_file = "data/rcrainfo/hd/NDV_HANDLER_NAICS_CODES.md") {
  naics_oz <- str_remove(read_lines(oz_file), "\\(0\\)$")
  naics_md <- read_lines(md_file)
  naics_valid6 <- unique(c(
    unlist(str_extract_all(naics_md, "\\b\\d{6}\\b")),
    paste0(str_remove(unlist(str_extract_all(naics_md, "\\b\\d{5}\\(0\\)")), "\\(0\\)"), "0"),
    # NAICS-2022 codes in live use that the md scrape lacks (validated 2026-07-13
    # against HD_MASTER: 2,043 records carry them)
    c("623110", "333310", "334510", "623210", "423620", "335220",
      "624410", "516120", "516210", "519290", "315120")))

  nrec <- rec |>
    filter(!is.na(date), !is.na(NAICS_CODE), NAICS_CODE != "", rcv_year >= 1980) |>
    mutate(code = str_trim(NAICS_CODE),
           code = if_else(code %in% naics_oz, paste0(code, "0"), code),
           code = if_else(code == "517110", "517111", code),
           code = if_else(str_detect(code, "^\\d{6}$") & !code %in% naics_valid6,
                          NA_character_, code),
           seq  = suppressWarnings(as.integer(NAICS_SEQ)),
           snum = suppressWarnings(as.integer(SEQ_NUMBER))) |>
    filter(!is.na(code)) |>
    distinct(HANDLER_ID, rcv_year, date, seq, snum, code)

  # submission windows within each facility x receive year
  naics_subs <- nrec |>
    distinct(HANDLER_ID, rcv_year, date) |>
    group_by(HANDLER_ID, rcv_year) |>
    arrange(date, .by_group = TRUE) |>
    mutate(dur = as.integer(coalesce(lead(date), ymd(paste0(rcv_year, "1231")) + 1) - date)) |>
    ungroup()

  naics_cand <- nrec |>
    left_join(naics_subs, by = c("HANDLER_ID", "rcv_year", "date"))

  naics_slots <- naics_cand |>
    arrange(HANDLER_ID, rcv_year, is.na(seq), seq, desc(dur), desc(date), desc(snum)) |>
    distinct(HANDLER_ID, rcv_year, code, .keep_all = TRUE) |>
    group_by(HANDLER_ID, rcv_year) |>
    arrange(is.na(seq), seq, desc(dur), desc(date), desc(snum), .by_group = TRUE) |>
    slice_head(n = 4) |>
    mutate(slot = paste0("NAICS6_", row_number())) |>
    ungroup() |>
    select(HANDLER_ID, rcv_year, slot, code) |>
    pivot_wider(names_from = slot, values_from = code)

  naics_four <- naics_cand |>
    group_by(HANDLER_ID, rcv_year) |>
    filter(dur == max(dur)) |>
    filter(date == max(date)) |>
    arrange(is.na(seq), seq, desc(snum), .by_group = TRUE) |>
    slice(1) |>
    ungroup() |>
    transmute(HANDLER_ID, rcv_year,
              NAICS4 = if_else(str_detect(code, "^\\d{4}"), str_sub(code, 1, 4), NA_character_))

  naics_year <- full_join(naics_four, naics_slots, by = c("HANDLER_ID", "rcv_year"))

  # facility-year assignment: in-year when any record was received, else carry
  naics_fy <- panel |> distinct(HANDLER_ID, REPORT_CYCLE) |>
    mutate(cyc = as.integer(REPORT_CYCLE))
  hd_recv_years <- rec |> filter(!is.na(date)) |> distinct(HANDLER_ID, rcv_year)

  naics_direct <- naics_fy |>
    semi_join(hd_recv_years, by = c("HANDLER_ID", "cyc" = "rcv_year")) |>
    left_join(naics_year, by = c("HANDLER_ID", "cyc" = "rcv_year"))

  naics_carried <- naics_fy |>
    anti_join(hd_recv_years, by = c("HANDLER_ID", "cyc" = "rcv_year")) |>
    left_join(naics_year, by = "HANDLER_ID", relationship = "many-to-many") |>
    filter(!is.na(rcv_year), rcv_year < cyc) |>
    group_by(HANDLER_ID, REPORT_CYCLE) |>
    slice_max(rcv_year, n = 1, with_ties = FALSE) |>
    ungroup()

  bind_rows(naics_direct, naics_carried) |>
    select(HANDLER_ID, REPORT_CYCLE,
           any_of(c("NAICS4", "NAICS6_1", "NAICS6_2", "NAICS6_3", "NAICS6_4")))
}

# Duration-dominant status of one HD_MASTER column over each report cycle's
# calendar year: collapse same-day disagreements to the most severe value,
# build the step-function timeline, and pick the value holding the most days
# of the window (day ties break on severity).
dominant <- function(rec, windows, value_col, sev_map, out_name, recode_map = NULL) {
  base <- rec |>
    filter(!is.na(date), !is.na(.data[[value_col]])) |>
    rename(val = all_of(value_col))
  # Recode to the canonical form BEFORE ranking, so same-day collapse and
  # duration ties use the real severity hierarchy (raw codes 1/2/3 are not the
  # keys of sev_map; only the recoded L/S/VS/N/P/U are).
  if (!is.null(recode_map)) base <- mutate(base, val = unname(recode_map[val]))
  base <- mutate(base, sev = coalesce(sev_map[val], -1L))

  timeline <- base |>
    # collapse same handler+date disagreements to the most severe value
    group_by(HANDLER_ID, date) |>
    slice_max(sev, n = 1, with_ties = FALSE) |>
    ungroup() |>
    arrange(HANDLER_ID, date) |>
    group_by(HANDLER_ID) |>
    mutate(iend = lead(date, default = as.Date("2100-01-01"))) |>
    ungroup() |>
    select(HANDLER_ID, istart = date, iend, val, sev)

  timeline |>
    cross_join(windows) |>
    mutate(days = pmax(as.integer(pmin(iend, wend + 1) - pmax(istart, wstart)), 0L)) |>
    filter(days > 0) |>
    group_by(HANDLER_ID, REPORT_CYCLE, val) |>
    summarise(days = sum(days), sev = first(sev), .groups = "drop") |>
    group_by(HANDLER_ID, REPORT_CYCLE) |>
    arrange(desc(days), desc(sev)) |>
    slice(1) |>
    ungroup() |>
    select(HANDLER_ID, REPORT_CYCLE, "{out_name}" := val)
}

# Batch dominance for the remaining HD attributes, one pass over every
# attribute column; each step interval is expanded only to the panel years it
# actually overlaps (rather than cross-joined against all years) to keep the
# intermediate small. Two regimes:
#   - 1/0 activity indicators (ind_src): severity-dominant on 1 > 0 > U
#     (ind_sev). A facility that is classified as, e.g., a slab importer at
#     ANY point of the calendar year is one that year (1 beats 0 and U
#     regardless of days held, and a real 0 beats an unknown U); duration then
#     most recent break residual ties among equal values.
#   - Plain descriptive attributes (location fields): duration-dominant, most
#     days of the calendar year wins, day ties toward the most recently
#     received value.
dominant_attrs <- function(rec, panel_years) {
  plain_src <- c("ACTIVITY_LOCATION", "LOCATION_STATE", "COUNTY_CODE", "REGION",
                 "LOCATION_LATITUDE", "LOCATION_LONGITUDE")
  ind_src   <- setdiff(names(hd_attr_map), plain_src)

  rec |>
    select(HANDLER_ID, date, all_of(names(hd_attr_map))) |>
    filter(!is.na(date)) |>
    pivot_longer(all_of(names(hd_attr_map)), names_to = "src", values_to = "val") |>
    filter(!is.na(val), val != "") |>
    distinct(HANDLER_ID, src, date, val) |>
    # Indicator severity (1 > 0 > U, unmapped codes lowest); plain attributes
    # get a constant so days and recency decide for them.
    mutate(sev = if_else(src %in% ind_src, coalesce(ind_sev[val], -1L), 0L)) |>
    # same handler+field+date disagreement -> the higher status wins (1 > 0 > U
    # for the indicators; max value otherwise), per the conflict-resolution tiers
    group_by(HANDLER_ID, src, date) |>
    slice_max(tibble(sev, val), n = 1, with_ties = FALSE) |>
    # step function: each value holds from its date to the next date for that field
    group_by(HANDLER_ID, src) |>
    arrange(date, .by_group = TRUE) |>
    mutate(iend = lead(date, default = as.Date("2100-01-01"))) |>
    ungroup() |>
    filter(iend > ymd(paste0(min(panel_years), "0101")),
           date <= ymd(paste0(max(panel_years), "1231"))) |>
    mutate(y0 = pmax(year(date), min(panel_years)),
           y1 = pmin(year(iend - 1), max(panel_years))) |>
    filter(y1 >= y0) |>
    mutate(yr = map2(y0, y1, seq)) |>
    unnest(yr) |>
    mutate(days = as.integer(pmin(iend, ymd(paste0(yr, "1231")) + 1) -
                               pmax(date, ymd(paste0(yr, "0101"))))) |>
    filter(days > 0) |>
    group_by(HANDLER_ID, REPORT_CYCLE = as.character(yr), src, val) |>
    summarise(days = sum(days), last_date = max(date), sev = first(sev),
              .groups = "drop") |>
    group_by(HANDLER_ID, REPORT_CYCLE, src) |>
    # Indicators rank severity first (1 > 0 > U); plain attributes share a
    # constant severity, so days then recency decide.
    arrange(desc(sev), desc(days), desc(last_date), .by_group = TRUE) |>
    slice(1) |>
    ungroup() |>
    mutate(field = unname(hd_attr_map[src])) |>
    select(HANDLER_ID, REPORT_CYCLE, field, val) |>
    pivot_wider(names_from = field, values_from = val)
}

# Build one BR facility-cycle panel end to end and write it. balanced = TRUE
# for the all-cycles panel, FALSE for the at-least-one-cycle superset.
build_br_panel <- function(balanced, out_file,
                           cycles   = seq(2015L, 2023L, by = 2L),
                           br_dir   = "data/rcrainfo/br",
                           hd_file  = "output/modular_master_files/HD_MASTER.csv",
                           frs_file = "data/frs/FRS_PROGRAM_LINKS.csv") {
  panel_years <- cycles                      # panel row-years (odd cycles only)

  # 1. Biennial Report: LQG/TSDF membership + facility-year tonnages
  panel <- br_membership(cycles, br_dir, balanced)
  ids   <- unique(panel$HANDLER_ID)

  # 2. Handler master: duration-dominant attributes + conflict string
  rec       <- read_hd_records(hd_file, ids)
  conflicts <- hd_conflicts(rec)
  rec_count <- hd_record_count(rec)
  naics5    <- naics_facility_year(rec, panel)

  # Duration-dominant status over each report cycle's calendar year.
  windows <- tibble(REPORT_CYCLE = as.character(panel_years),
                    wstart = ymd(paste0(panel_years, "0101")),
                    wend   = ymd(paste0(panel_years, "1231")))
  # The three severity-ranked statuses, each on its own hierarchy: federal
  # generator (recoded to L/S/VS/...), TSDF (Y > N), and state generator
  # (ranked via the federal mapping; the raw state code is kept as the output).
  dom_gen   <- dominant(rec, windows, "FED_WASTE_GENERATOR",   gen_sev,   "HD_GENERATOR", recode_gen)
  dom_tsd   <- dominant(rec, windows, "TSD_ACTIVITY",          tsd_sev,   "HD_TSDF")
  dom_state <- dominant(rec, windows, "STATE_WASTE_GENERATOR", state_sev, "HD_STATE_GENERATOR")
  dom_attrs <- dominant_attrs(rec, panel_years)

  # FRS: Facility Registry Service ID
  frs <- read_frs_links(ids, frs_file)

  # 3. Assemble and write
  out <- panel |>
    left_join(frs,       by = "HANDLER_ID") |>
    left_join(conflicts, by = c("HANDLER_ID", "REPORT_CYCLE")) |>
    left_join(dom_gen,   by = c("HANDLER_ID", "REPORT_CYCLE")) |>
    left_join(dom_tsd,   by = c("HANDLER_ID", "REPORT_CYCLE")) |>
    left_join(dom_state, by = c("HANDLER_ID", "REPORT_CYCLE")) |>
    left_join(dom_attrs, by = c("HANDLER_ID", "REPORT_CYCLE")) |>
    left_join(naics5,    by = c("HANDLER_ID", "REPORT_CYCLE")) |>
    left_join(rec_count, by = c("HANDLER_ID", "REPORT_CYCLE")) |>
    mutate(HD_RECORD_COUNT = replace_na(HD_RECORD_COUNT, 0L)) |>
    # FED_WASTE_GENERATOR conflicts defer to the Biennial Report: where HD_GENERATOR
    # is flagged in HD_CONFLICTS, overwrite it with BR_GENERATOR (the Biennial
    # Report LQG status).
    mutate(HD_GENERATOR = if_else(
      !is.na(HD_CONFLICTS) & str_detect(HD_CONFLICTS, "(^|;)HD_GENERATOR(;|$)"),
      BR_GENERATOR, HD_GENERATOR)) |>
    # Format tonnages as clean fixed-decimal strings at the raw 7-dp precision, so
    # the CSV carries no binary floating-point summation noise (16.014999999999997
    # -> "16.015"); the sub() trims trailing zeros and any bare decimal point.
    mutate(across(all_of(tons_cols), \(x) sub("\\.?0+$", "", sprintf("%.7f", x))))

  # Any HD attribute with no non-empty value anywhere yields no column from the
  # pivot; add it back as NA so the schema (hd_order) is always complete.
  miss <- setdiff(hd_order, names(out))
  if (length(miss)) out[miss] <- NA_character_

  out <- out |>
    select(HANDLER_ID, FRS_ID, REPORT_CYCLE, HD_CONFLICTS,
           BR_GENERATOR, BR_TSDF,
           BR_GENERATE_TONS, BR_MANAGE_TONS, BR_SHIP_TONS, BR_RECEIVE_TONS,
           all_of(hd_order)) |>
    arrange(HANDLER_ID, REPORT_CYCLE)

  write_panel(out, out_file)
}
