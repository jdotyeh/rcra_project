# =============================================================================
# 01_panel_2015_2023_balanced.R
#
# Facility-cycle panel of RCRA handlers recognized in the National Biennial
# Report (NBR) as large quantity generators (LQGs) and/or treatment, storage
# and disposal facilities (TSDFs), report cycles 2015-2023 (odd years only). One
# row per handler x cycle; balanced, so only handlers recognized as LQG and/or
# TSDF in ALL five cycles are kept (5 rows per handler: 2015/2017/2019/2021/2023).
#
# Columns
#   HANDLER_ID, FRS_ID, REPORT_CYCLE
#   FRS_ID             EPA Facility Registry Service REGISTRY_ID, linked from the
#                      FRS Program Links file on the RCRAInfo Handler ID
#                      (PGM_SYS_ID where PGM_SYS_ACRNM == "RCRAINFO"). One
#                      REGISTRY_ID per Handler ID; NA if no RCRAINFO link exists.
#   HD_CONFLICTS       ";"-delimited list of the HD_* fields (panel names) that
#                      carried >= 2 distinct values RECEIVED within the row's
#                      calendar year (e.g. two FED_WASTE_GENERATOR codes filed in
#                      2019). Empty when nothing conflicts. Replaces the old
#                      per-field HD_GENERATOR_CONF / HD_TSDF_CONF booleans.
#   BR_GENERATOR       "L" if any BR_REPORTING row that cycle has
#                      CALCULATED_GENERATOR_STATUS == "L", else "N".
#   BR_TSDF            "Y" if any row that cycle has MGMT_ID_INCLUDED_IN_NBR or
#                      RECV_ID_INCLUDED_IN_NBR == "Y", else "N".
#   BR_GENERATE_TONS   Facility-year Biennial Report tonnages, summed over the
#   BR_MANAGE_TONS     BR_REPORTING waste lines, each restricted to the lines
#   BR_SHIP_TONS       EPA counts toward the matching NBR quantity total
#   BR_RECEIVE_TONS    (<x> WASTE INCLUDED IN NBR == "Y"); this keeps the totals
#                      on the panel's NBR basis and avoids double counting.
#                      Written as clean fixed-decimal strings (<=7 dp).
#   HD_*               Handler-master (HD_MASTER) attributes, one value per
#                      facility-year by the SAME duration-dominant rule as
#                      HD_GENERATOR: the value holding the most days of the
#                      calendar year, every source record setting a value from
#                      its RECEIVE_DATE forward (step function) and carrying the
#                      last value before Jan 1 in, so a site that switches on
#                      12/31 keeps its Jan-Dec value that year. Day ties break
#                      toward the most recently received value (HD_GENERATOR /
#                      HD_TSDF instead break on severity: L>S>VS>N>P>U, Y>N).
#                      Source column -> panel name:
#                        HD_ACTIVITY_STATE      <- ACTIVITY_LOCATION
#                        HD_LOCATION_STATE      <- LOCATION_STATE
#                        HD_LOCATION_COUNTY     <- COUNTY_CODE
#                        HD_EPA_REGION          <- REGION
#                        HD_LOCATION_LATITUDE   <- LOCATION_LATITUDE
#                        HD_LOCATION_LONGITUDE  <- LOCATION_LONGITUDE
#                        HD_NAICS_CODE          <- NAICS_CODE (NAICS_SEQ == 1 only)
#                        HD_GENERATOR           <- FED_WASTE_GENERATOR (1->L,2->S,3->VS;
#                          same-year conflicts overridden by BR_GENERATOR)
#                        HD_STATE_GENERATOR     <- STATE_WASTE_GENERATOR (ranked on the
#                          federal hierarchy L=1>S=2>VS=3>N; non-convertible codes lowest)
#                        HD_SHORT_TERM_GENERATOR<- SHORT_TERM_GENERATOR
#                        HD_TSDF                <- TSD_ACTIVITY
#                        HD_RECYCLER_STORAGE    <- RECYCLER_ACTIVITY
#                        HD_RECYCLER_NONSTORAGE <- RECYCLER_ACTIVITY_NONSTORAGE
#                        HD_IMPORTER            <- IMPORTER_ACTIVITY
#                        HD_RECOGNIZED_TRADER_IMPORTER <- RECOGNIZED_TRADER_IMPORTER
#                        HD_RECOGNIZED_TRADER_EXPORTER <- RECOGNIZED_TRADER_EXPORTER
#                        HD_SLAB_IMPORTER       <- SLAB_IMPORTER
#                        HD_SLAB_EXPORTER       <- SLAB_EXPORTER
#                        HD_TRANSPORTER         <- TRANSPORTER
#                        HD_TRANSFER_FACILITY   <- TRANSFER_FACILITY
#                        HD_ONSITE_BURNER_EXEMPTION <- ONSITE_BURNER_EXEMPTION
#                        HD_FURNACE_EXEMPTION   <- FURNACE_EXEMPTION
#                        HD_UNDERGROUND_INJECTION_ACTIVITY <- UNDERGROUND_INJECTION_ACTIVITY
#                        HD_OFF_SITE_RECEIPT    <- OFF_SITE_RECEIPT
#                        HD_UNIVERSAL_WASTE_LQ_HANDLER    <- LQHUW
#                        HD_UNIVERSAL_WASTE_DEST_FACILITY <- UNIVERSAL_WASTE_DEST_FACILITY
#                        HD_USED_OIL_* (7)      <- USED_OIL_* (TRANSPORTER,
#                          TRANSFER_FACILITY, PROCESSOR, REFINER, BURNER,
#                          MARKET_BURNER, SPEC_MARKETER)
#   HD_RECORD_COUNT    Number of HD_MASTER source records (distinct
#                      SOURCE_TYPE x SEQ_NUMBER) RECEIVED in the row's calendar
#                      year, pooled across all source types; 0 if none.
#
# BR_* come from BR_REPORTING_<cycle> (waste-line level, aggregated to the
# facility-year). HD_* come from the handler notification history in HD_MASTER
# and are independent of the BR filing, so they can legitimately disagree with
# BR_GENERATOR / BR_TSDF.
#
# Conflict resolution (one design, three tiers). Timelines are built per
# HANDLER_ID across all source records; records sharing a RECEIVE_DATE collapse
# to ONE value before the timeline, and the rule that picks it depends on the
# variable:
#   1. FED_WASTE_GENERATOR  most-severe wins on the day (gen_sev), and any
#                           facility-year still flagged in HD_CONFLICTS is then
#                           overridden by BR_GENERATOR -- the biennial report is
#                           authoritative for the federal generator status.
#   2. Y/N indicators       higher status wins: Y > N (tsd_sev for TSD_ACTIVITY;
#                           slice_max(val) does the same for the batch attrs).
#   3. STATE_WASTE_GENERATOR state code mapped to the federal hierarchy
#                           (L=1 > S=2 > VS=3 > N, state_sev) and the higher
#                           status wins; codes with no federal mapping rank
#                           below everything. The two 2015 non-convertible
#                           cases (KYR000029207 D|S, LAR000053413 7|N) were
#                           manually reviewed and confirmed to the convertible
#                           partner (S and N) -- exactly what the rule yields.
# HD_CONFLICTS still lists every same-year disagreement (audit trail): a listed
# field means the inputs disagreed, not that the resolved value is in doubt.
#
# Requires: tidyverse (incl. lubridate)
# =============================================================================

library(tidyverse)

br_dir   <- "data/rcrainfo/br"
hd_file  <- "output/modular_master_files/HD_MASTER.csv"
frs_file <- "data/frs/FRS_PROGRAM_LINKS.csv"
out_file <- "output/panels/BR_PANEL_2015_2023_BALANCED.csv"
cycles      <- seq(2015L, 2023L, by = 2L)   # biennial report cycles (odd years)
panel_years <- cycles                       # panel row-years (odd cycles only)

# Recode + severity (higher = more severe) for the HD_MASTER status timelines.
gen_sev    <- c(L = 5L, S = 4L, VS = 3L, N = 2L, P = 1L, U = 0L)
tsd_sev    <- c(Y = 1L, N = 0L)
# State generator resolved on the FEDERAL hierarchy: convert the state code
# (L=1 > S=2 > VS=3 > N), numerics already federal. Codes outside this set have
# no federal mapping -> severity -1 via coalesce, so they never beat a
# convertible code (see "Conflict resolution" in the header).
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
  NAICS_CODE                     = "HD_NAICS_CODE",
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
  "HD_LOCATION_LATITUDE", "HD_LOCATION_LONGITUDE", "HD_NAICS_CODE", "HD_RECORD_COUNT",
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

# -- 1. Biennial Report: LQG/TSDF membership + facility-year tonnages ----------
# One row per handler x cycle that is an LQG and/or TSDF that cycle; a single
# read of BR_REPORTING serves both the membership flags and the tonnage sums.
br_one_cycle <- function(year) {
  br <- read_csv(file.path(br_dir, sprintf("BR_REPORTING_%d.csv", year)),
                 col_types = cols(.default = "c"), show_col_types = FALSE,
                 col_select = c(`HANDLER ID`, `CALCULATED GENERATOR STATUS`,
                                `MGMT ID INCLUDED IN NBR`, `RECV ID INCLUDED IN NBR`,
                                `GENERATION TONS`, `MANAGED TONS`,
                                `SHIPPED TONS`, `RECEIVED TONS`,
                                `GEN WASTE INCLUDED IN NBR`, `MGMT WASTE INCLUDED IN NBR`,
                                `SHIP WASTE INCLUDED IN NBR`, `RECV WASTE INCLUDED IN NBR`))
  names(br) <- gsub(" ", "_", names(br))

  br |>
    mutate(across(ends_with("_TONS"), as.numeric)) |>
    group_by(HANDLER_ID) |>
    summarise(
      BR_GENERATOR = if_else(any(CALCULATED_GENERATOR_STATUS == "L", na.rm = TRUE), "L", "N"),
      BR_TSDF      = if_else(any(MGMT_ID_INCLUDED_IN_NBR == "Y" |
                                   RECV_ID_INCLUDED_IN_NBR == "Y", na.rm = TRUE), "Y", "N"),
      BR_GENERATE_TONS = sum(GENERATION_TONS[GEN_WASTE_INCLUDED_IN_NBR == "Y"], na.rm = TRUE),
      BR_MANAGE_TONS   = sum(MANAGED_TONS[MGMT_WASTE_INCLUDED_IN_NBR == "Y"],    na.rm = TRUE),
      BR_SHIP_TONS     = sum(SHIPPED_TONS[SHIP_WASTE_INCLUDED_IN_NBR == "Y"],    na.rm = TRUE),
      BR_RECEIVE_TONS  = sum(RECEIVED_TONS[RECV_WASTE_INCLUDED_IN_NBR == "Y"],   na.rm = TRUE),
      .groups = "drop") |>
    filter(BR_GENERATOR == "L" | BR_TSDF == "Y") |>
    mutate(REPORT_CYCLE = as.character(year))
}

panel <- map(cycles, br_one_cycle) |>
  list_rbind() |>
  group_by(HANDLER_ID) |>
  filter(n_distinct(REPORT_CYCLE) == length(cycles)) |>
  ungroup()

ids <- unique(panel$HANDLER_ID)

# -- 2. Handler master: duration-dominant attributes + conflict string ---------
rec <- read_csv(hd_file, col_types = cols(.default = "c"), show_col_types = FALSE,
                col_select = c(HANDLER_ID, SOURCE_TYPE, SEQ_NUMBER, NAICS_SEQ,
                               RECEIVE_DATE, all_of(names(hd_all_map)))) |>
  filter(HANDLER_ID %in% ids) |>
  # NAICS_CODE is meaningful only on the primary NAICS row (NAICS_SEQ == 1);
  # blank it elsewhere so dominance and conflicts see the primary code alone.
  mutate(NAICS_CODE = if_else(NAICS_SEQ == "1", NAICS_CODE, NA_character_)) |>
  distinct() |>
  mutate(date = ymd(RECEIVE_DATE), RY = year(date))

# HD_CONFLICTS: for each facility-year, panel names of the HD_* fields carrying
# >= 2 distinct values RECEIVED in that calendar year, ";"-joined in schema
# (hd_order) order. Rows with no conflict are absent here (written as "").
conflicts <- rec |>
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

# HD_RECORD_COUNT: source records (distinct SOURCE_TYPE x SEQ_NUMBER) received
# in the calendar year, pooled across all source types.
rec_count <- rec |>
  filter(!is.na(RY)) |>
  distinct(HANDLER_ID, RY, SOURCE_TYPE, SEQ_NUMBER) |>
  count(HANDLER_ID, REPORT_CYCLE = as.character(RY), name = "HD_RECORD_COUNT")

# Duration-dominant status over each report cycle's calendar year (odd cycles).
windows <- tibble(REPORT_CYCLE = as.character(panel_years),
                  wstart = ymd(paste0(panel_years, "0101")),
                  wend   = ymd(paste0(panel_years, "1231")))

dominant <- function(value_col, sev_map, out_name, recode_map = NULL) {
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
# The three severity-ranked statuses, each on its own hierarchy (see header):
# federal generator (recoded to L/S/VS/...), TSDF (Y > N), and state generator
# (ranked via the federal mapping; the raw state code is kept as the output).
dom_gen   <- dominant("FED_WASTE_GENERATOR",   gen_sev,   "HD_GENERATOR", recode_gen)
dom_tsd   <- dominant("TSD_ACTIVITY",          tsd_sev,   "HD_TSDF")
dom_state <- dominant("STATE_WASTE_GENERATOR", state_sev, "HD_STATE_GENERATOR")

# Batch duration-dominant for the plain (no-severity) HD attributes: same
# most-days-of-the-calendar-year rule as HD_GENERATOR, but day ties break toward
# the most recently received value. One pass over every attribute column; each
# step interval is expanded only to the panel years it actually overlaps (rather
# than cross-joined against all years) to keep the intermediate small.
dom_attrs <- rec |>
  select(HANDLER_ID, date, all_of(names(hd_attr_map))) |>
  filter(!is.na(date)) |>
  pivot_longer(all_of(names(hd_attr_map)), names_to = "src", values_to = "val") |>
  filter(!is.na(val), val != "") |>
  distinct(HANDLER_ID, src, date, val) |>
  # same handler+field+date disagreement -> the higher status wins (Y > N for
  # the indicators; max() generally), per the header's conflict-resolution tiers
  group_by(HANDLER_ID, src, date) |>
  slice_max(val, n = 1, with_ties = FALSE) |>
  # step function: each value holds from its date to the next date for that field
  group_by(HANDLER_ID, src) |>
  arrange(date, .by_group = TRUE) |>
  mutate(iend = lead(date, default = as.Date("2100-01-01"))) |>
  ungroup() |>
  filter(iend > ymd("20150101"), date <= ymd("20231231")) |>
  mutate(y0 = pmax(year(date), min(panel_years)),
         y1 = pmin(year(iend - 1), max(panel_years))) |>
  filter(y1 >= y0) |>
  mutate(yr = map2(y0, y1, seq)) |>
  unnest(yr) |>
  mutate(days = as.integer(pmin(iend, ymd(paste0(yr, "1231")) + 1) -
                             pmax(date, ymd(paste0(yr, "0101"))))) |>
  filter(days > 0) |>
  group_by(HANDLER_ID, REPORT_CYCLE = as.character(yr), src, val) |>
  summarise(days = sum(days), last_date = max(date), .groups = "drop") |>
  group_by(HANDLER_ID, REPORT_CYCLE, src) |>
  arrange(desc(days), desc(last_date), .by_group = TRUE) |>
  slice(1) |>
  ungroup() |>
  mutate(field = unname(hd_attr_map[src])) |>
  select(HANDLER_ID, REPORT_CYCLE, field, val) |>
  pivot_wider(names_from = field, values_from = val)

# -- FRS: Facility Registry Service ID -----------------------------------------
# Link each handler to its FRS REGISTRY_ID through the FRS Program Links file,
# matching the RCRAInfo Handler ID against PGM_SYS_ID on the RCRAINFO program
# rows. RCRAINFO PGM_SYS_ID -> REGISTRY_ID is 1:1, so this stays one row per
# handler and the downstream join does not fan out the panel.
frs <- read_csv(frs_file, col_types = cols(.default = "c"), show_col_types = FALSE,
                col_select = c(PGM_SYS_ACRNM, PGM_SYS_ID, REGISTRY_ID)) |>
  filter(PGM_SYS_ACRNM == "RCRAINFO", PGM_SYS_ID %in% ids) |>
  distinct(HANDLER_ID = PGM_SYS_ID, FRS_ID = REGISTRY_ID)

# -- 3. Assemble and write -----------------------------------------------------
out <- panel |>
  left_join(frs,       by = "HANDLER_ID") |>
  left_join(conflicts, by = c("HANDLER_ID", "REPORT_CYCLE")) |>
  left_join(dom_gen,   by = c("HANDLER_ID", "REPORT_CYCLE")) |>
  left_join(dom_tsd,   by = c("HANDLER_ID", "REPORT_CYCLE")) |>
  left_join(dom_state, by = c("HANDLER_ID", "REPORT_CYCLE")) |>
  left_join(dom_attrs, by = c("HANDLER_ID", "REPORT_CYCLE")) |>
  left_join(rec_count, by = c("HANDLER_ID", "REPORT_CYCLE")) |>
  mutate(HD_RECORD_COUNT = replace_na(HD_RECORD_COUNT, 0L)) |>
  # FED_WASTE_GENERATOR conflicts defer to the biennial report: where HD_GENERATOR
  # is flagged in HD_CONFLICTS, overwrite it with BR_GENERATOR (the NBR LQG status).
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

dir.create(dirname(out_file), showWarnings = FALSE, recursive = TRUE)
write_csv(out, out_file, na = "")
