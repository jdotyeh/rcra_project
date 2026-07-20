# =============================================================================
# 23_panel_facilities.R  (coherent facility set + YEAR-SPECIFIC LQG / TSDF status)
#
# Identify the COHERENT SET of facilities for a biennial-report panel and attach
# each facility's generator/TSDF status AS OF EACH CYCLE (not its status today).
#
# Definition (per project decisions):
#   * AT-LEAST-ONCE panel: a facility is kept if it filed a biennial report as an
#     LQG in AT LEAST ONE odd cycle from 2015 to 2023 (2015, 2017, 2019, 2021,
#     2023) -- the UNION across cycles, NOT the balanced intersection.  (Earlier
#     versions kept only sites that were LQG in every cycle; that is the wrong
#     universe for "identifies at least once as an LQG during 2015-2023".)
#   * Presence in a cycle is counted from CALCULATED GENERATOR STATUS == "L"
#     (LQG) lines  (BR_STATUS_KEEP below).  VSQGs / transporters never file an
#     LQG line, so they are excluded by construction over the study window.
#
#   * YEAR-SPECIFIC STATUS: for each (facility, cycle) we read the contemporaneous
#     handler record from HD_HANDLER (which is historical, keyed by REPORT CYCLE)
#     and set
#         LQG  = 1  if FED WASTE GENERATOR == "1" (Large Quantity Generator) that cycle
#         TSDF = 1  if TSD ACTIVITY == "Y"        (treat/store/dispose)       that cycle
#     SQG-status years are the implicit baseline (LQG = 0, TSDF = 0).
#
#   * We deliberately DO NOT filter the set on the *current* (HD_REPORTING)
#     snapshot.  A site that was an LQG during 2015-2023 but is an SQG/VSQG today
#     must stay in, flagged by its status in each year.  (Earlier versions used
#     the current snapshot; that is wrong for a historical panel.)
#
# Leaves in the environment:
#     coherent_facilities      - one row per facility (the at-least-once universe)
#     facility_status_by_year  - HANDLER_ID x year, with year-specific LQG / TSDF
# Writes: output/diagnostics/coherent_panel_facilities.csv  (one row per
#         facility; brL_<cycle> = BR-LQG presence that cycle [the set-defining
#         metric]; LQG_<cycle> / TSDF_<cycle> = contemporaneous HD_HANDLER
#         status; n_cycles_brL = how many of the 5 cycles the site was a BR LQG).
#
# Requires: tidyverse (readr, dplyr, tidyr, purrr, stringr, tibble)
# =============================================================================

library(readr)
library(dplyr)
library(tidyr)
library(purrr)
library(stringr)
library(tibble)

# ---- Parameters -------------------------------------------------------------
PANEL_YEARS    <- seq(2015L, 2023L, by = 2L)   # 2015, 2017, 2019, 2021, 2023
BR_STATUS_KEEP <- c("L")                        # BR CALCULATED GENERATOR STATUS counted as "present"
BR_DIR         <- "data/rcrainfo/br"
HD_HANDLER_CSV <- "data/rcrainfo/hd/HD_HANDLER.csv"

clean_names <- function(df) rename_with(df, ~ str_replace_all(.x, " ", "_"))

# ---- Step 1: BR presence per cycle -----------------------------------------
br_facilities_for_year <- function(year) {
  f <- file.path(BR_DIR, sprintf("BR_REPORTING_%d.csv", year))
  stopifnot(file.exists(f))
  ids <- read_csv(f,
                  col_select = c(`HANDLER ID`, `CALCULATED GENERATOR STATUS`),
                  col_types  = cols(.default = col_character()),
                  show_col_types = FALSE, progress = FALSE) |>
    clean_names() |>
    filter(CALCULATED_GENERATOR_STATUS %in% BR_STATUS_KEEP,
           !is.na(HANDLER_ID), HANDLER_ID != "") |>
    distinct(HANDLER_ID) |>
    mutate(year = year)
  message(sprintf("  %d: %s LQG-reporting facilities", year, format(nrow(ids), big.mark = ",")))
  ids
}

message("Reading biennial reports (HANDLER_ID x cycle, status in {",
        paste(BR_STATUS_KEEP, collapse = ", "), "}) ...")
br_long <- map(PANEL_YEARS, br_facilities_for_year) |> bind_rows()

# ---- Step 2: at-least-once panel (LQG in >=1 cycle = UNION) -----------------
br_cycle_counts <- br_long |> count(HANDLER_ID, name = "n_cycles_brL")
lqg_ever_ids    <- br_cycle_counts |> pull(HANDLER_ID)   # union of all LQG-L filers

message(sprintf("At-least-once panel (LQG filer in >=1 of %d cycles): %s facilities",
                length(PANEL_YEARS), format(length(lqg_ever_ids), big.mark = ",")))
message("  distribution of #cycles a site was a BR LQG:")
print(br_cycle_counts |> count(n_cycles_brL, name = "facilities"))

# ---- Step 3: YEAR-SPECIFIC status from HD_HANDLER ---------------------------
# HD_HANDLER is historical: it carries one (or a few) records per HANDLER_ID per
# REPORT CYCLE.  We keep the panel facilities & cycles, then collapse to one
# record per (facility, cycle): prefer CURRENT RECORD == "Y", then latest
# RECEIVE DATE.
message("Reading HD_HANDLER for contemporaneous (per-cycle) status ...")
cycle_chr <- as.character(PANEL_YEARS)

hd_hist <- read_csv(HD_HANDLER_CSV,
                    col_select = c(`HANDLER ID`, `REPORT CYCLE`, `RECEIVE DATE`, `CURRENT RECORD`,
                                   `FED WASTE GENERATOR`, `TSD ACTIVITY`, TRANSPORTER),
                    col_types  = cols(.default = col_character()),
                    show_col_types = FALSE, progress = FALSE) |>
  clean_names() |>
  filter(HANDLER_ID %in% lqg_ever_ids, REPORT_CYCLE %in% cycle_chr) |>
  mutate(year = as.integer(REPORT_CYCLE)) |>
  arrange(HANDLER_ID, year, desc(CURRENT_RECORD == "Y"), desc(RECEIVE_DATE)) |>
  distinct(HANDLER_ID, year, .keep_all = TRUE)

# Full facility x cycle grid, left-joined to the contemporaneous record.
facility_status_by_year <- expand_grid(HANDLER_ID = lqg_ever_ids,
                                        year       = PANEL_YEARS) |>
  left_join(hd_hist |>
              transmute(HANDLER_ID, year,
                        fed_gen_status = FED_WASTE_GENERATOR,
                        tsd_activity   = TSD_ACTIVITY,
                        transporter    = TRANSPORTER),
            by = c("HANDLER_ID", "year")) |>
  mutate(
    has_handler_record = !is.na(fed_gen_status) | !is.na(tsd_activity),
    LQG  = as.integer(fed_gen_status %in% "1"),
    TSDF = as.integer(tsd_activity   %in% "Y")
  )

# ---- Step 4: facility universe ---------------------------------------------
coherent_facilities <- tibble(HANDLER_ID = lqg_ever_ids)

# ---- Report -----------------------------------------------------------------
n_missing <- sum(!facility_status_by_year$has_handler_record)
message("\n================ COHERENT FACILITY SET ================")
message(sprintf("Facilities (at-least-once LQG)  : %s", format(nrow(coherent_facilities), big.mark = ",")))
message(sprintf("Facility-years                 : %s", format(nrow(facility_status_by_year), big.mark = ",")))
message(sprintf("Facility-years w/o HD_HANDLER record (LQG/TSDF set 0): %s",
                format(n_missing, big.mark = ",")))
message("Year-specific generator status (FED WASTE GENERATOR) by cycle:")
print(facility_status_by_year |> count(year, fed_gen_status) |>
        tidyr::pivot_wider(names_from = fed_gen_status, values_from = n, values_fill = 0))
message("Facilities whose LQG status changes across the window (LQG in some cycles, not others):")
chg <- facility_status_by_year |> group_by(HANDLER_ID) |>
  summarise(n_lqg = sum(LQG), .groups = "drop") |>
  filter(n_lqg > 0, n_lqg < length(PANEL_YEARS))
message(sprintf("  %s facilities", format(nrow(chg), big.mark = ",")))

# ---- Write facility-level reference (wide, status by year) ------------------
# brL_<cycle> = BR-LQG presence that cycle (the SET-DEFINING metric, calc status
# == "L"); LQG_<cycle> / TSDF_<cycle> = contemporaneous HD_HANDLER status.
br_presence <- br_long |>
  mutate(brL = 1L) |>
  pivot_wider(names_from = year, values_from = brL,
              names_prefix = "brL_", values_fill = 0L)

wide <- facility_status_by_year |>
  select(HANDLER_ID, year, LQG, TSDF) |>
  pivot_wider(names_from = year, values_from = c(LQG, TSDF), names_sep = "_") |>
  left_join(br_cycle_counts, by = "HANDLER_ID") |>
  left_join(br_presence,     by = "HANDLER_ID") |>
  relocate(HANDLER_ID, n_cycles_brL, starts_with("brL_"))
dir.create("output/diagnostics", showWarnings = FALSE, recursive = TRUE)
write_csv(wide, "output/diagnostics/coherent_panel_facilities.csv")
message(sprintf("Written -> output/diagnostics/coherent_panel_facilities.csv  (%s facilities)",
                format(nrow(wide), big.mark = ",")))
