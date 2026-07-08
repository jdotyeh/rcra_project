# =============================================================================
# 01_panel_2015_2023.R
#
# Facility-cycle panel of RCRA handlers recognized in the National Biennial
# Report (NBR) as large quantity generators (LQGs) and/or treatment, storage
# and disposal facilities (TSDFs), report cycles 2015-2023 (odd years). One row
# per handler x cycle; balanced, so only handlers recognized as LQG and/or TSDF
# in ALL five cycles are kept (5 rows per handler).
#
# Columns
#   HANDLER_ID, REPORT_CYCLE
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
#   HD_GENERATOR       Handler-master (HD_MASTER) FED_WASTE_GENERATOR recoded
#                      1->L, 2->S, 3->VS, N->N, P->P, U->U, taken as the status
#                      holding the most days of the cycle CALENDAR year: every
#                      source record sets a status from its RECEIVE_DATE forward
#                      (step function), carrying in the last status before Jan 1,
#                      so a site that switches L->VS on 12/31 is still L that
#                      year. Ties break on severity L > S > VS > N > P > U.
#   HD_GENERATOR_CONF  TRUE if >= 2 distinct FED_WASTE_GENERATOR values were
#                      RECEIVED within the cycle calendar year (e.g. one source
#                      record says 3 and another received that year says 2).
#   HD_TSDF            HD_MASTER TSD_ACTIVITY (Y/N), same duration rule (Y > N).
#   HD_TSDF_CONF       TRUE if >= 2 distinct TSD_ACTIVITY received in-year.
#
# BR_* come from BR_REPORTING_<cycle> (waste-line level, aggregated to the
# facility-year). HD_* come from the handler notification history in HD_MASTER
# and are independent of the BR filing, so they can legitimately disagree with
# BR_GENERATOR / BR_TSDF. HD status timelines are built per HANDLER_ID across
# all source records; records sharing a RECEIVE_DATE but disagreeing collapse to
# the most severe value for the timeline, and the disagreement still counts
# toward the _CONF flag.
#
# Requires: tidyverse (incl. lubridate)
# =============================================================================

library(tidyverse)

br_dir   <- "data/rcrainfo/br"
hd_file  <- "output/modular_master_files/HD_MASTER.csv"
out_file <- "output/panels/BR_PANEL_2015_2023.csv"
cycles   <- seq(2015L, 2023L, by = 2L)

# Recode + severity (higher = more severe) for the HD_MASTER status timelines.
gen_sev    <- c(L = 5L, S = 4L, VS = 3L, N = 2L, P = 1L, U = 0L)
tsd_sev    <- c(Y = 1L, N = 0L)
recode_gen <- c(`1` = "L", `2` = "S", `3` = "VS", N = "N", P = "P", U = "U")
tons_cols  <- c("BR_GENERATE_TONS", "BR_MANAGE_TONS", "BR_SHIP_TONS", "BR_RECEIVE_TONS")

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

# -- 2. Handler master: generator / TSDF status and conflict flags -------------
rec <- read_csv(hd_file, col_types = cols(.default = "c"), show_col_types = FALSE,
                col_select = c(HANDLER_ID, ACTIVITY_LOCATION, SOURCE_TYPE,
                               SEQ_NUMBER, RECEIVE_DATE,
                               FED_WASTE_GENERATOR, TSD_ACTIVITY)) |>
  filter(HANDLER_ID %in% ids) |>
  distinct() |>
  mutate(date = ymd(RECEIVE_DATE), RY = year(date))

# Conflict: >= 2 distinct values received in the cycle calendar year.
conf_flag <- function(value_col, out_name) {
  rec |>
    filter(!is.na(RY), !is.na(.data[[value_col]])) |>
    group_by(HANDLER_ID, REPORT_CYCLE = as.character(RY)) |>
    summarise("{out_name}" := n_distinct(.data[[value_col]]) > 1, .groups = "drop")
}
conf_gen <- conf_flag("FED_WASTE_GENERATOR", "HD_GENERATOR_CONF")
conf_tsd <- conf_flag("TSD_ACTIVITY",        "HD_TSDF_CONF")

# Duration-dominant status over each cycle's calendar year.
windows <- tibble(REPORT_CYCLE = as.character(cycles),
                  wstart = ymd(paste0(cycles, "0101")),
                  wend   = ymd(paste0(cycles, "1231")))

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
dom_gen <- dominant("FED_WASTE_GENERATOR", gen_sev, "HD_GENERATOR", recode_gen)
dom_tsd <- dominant("TSD_ACTIVITY",        tsd_sev, "HD_TSDF")

# -- 3. Assemble and write -----------------------------------------------------
out <- panel |>
  left_join(dom_gen,  by = c("HANDLER_ID", "REPORT_CYCLE")) |>
  left_join(dom_tsd,  by = c("HANDLER_ID", "REPORT_CYCLE")) |>
  left_join(conf_gen, by = c("HANDLER_ID", "REPORT_CYCLE")) |>
  left_join(conf_tsd, by = c("HANDLER_ID", "REPORT_CYCLE")) |>
  mutate(HD_GENERATOR_CONF = replace_na(HD_GENERATOR_CONF, FALSE),
         HD_TSDF_CONF      = replace_na(HD_TSDF_CONF, FALSE)) |>
  # Format tonnages as clean fixed-decimal strings at the raw 7-dp precision, so
  # the CSV carries no binary floating-point summation noise (16.014999999999997
  # -> "16.015"); the sub() trims trailing zeros and any bare decimal point.
  mutate(across(all_of(tons_cols), \(x) sub("\\.?0+$", "", sprintf("%.7f", x)))) |>
  select(HANDLER_ID, REPORT_CYCLE, BR_GENERATOR, BR_TSDF,
         BR_GENERATE_TONS, BR_MANAGE_TONS, BR_SHIP_TONS, BR_RECEIVE_TONS,
         HD_GENERATOR, HD_GENERATOR_CONF, HD_TSDF, HD_TSDF_CONF) |>
  arrange(HANDLER_ID, REPORT_CYCLE)

dir.create(dirname(out_file), showWarnings = FALSE, recursive = TRUE)
write_csv(out, out_file, na = "")
