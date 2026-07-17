# =============================================================================
# FILE:     02_panel_eval_2015_2023.R
# PURPOSE:  Build the balanced facility-month panel of RCRA compliance
#           evaluations from CE_MASTER, months 2015-01 through 2023-12, with the
#           FRS link.
# INPUTS:   output/modular_master_files/CE_MASTER.csv,
#           data/frs/FRS_PROGRAM_LINKS.csv; sources 00_panel_functions.R
# OUTPUTS:  output/panels/CE_PANEL_2015_2023/EVAL_PANEL_2015_2023.csv
#           (+ .rds twin with exact column types)
# AUTHOR:   Jason Ye
# CREATED:  2026-07-10
# UPDATED:  2026-07-16
# =============================================================================
#
# Facility-month panel of RCRA compliance evaluations built from CE_MASTER,
# calendar months 2015-01 through 2023-12. One row per handler x year x month;
# balanced over the full 108-month window for every handler with at least one
# evaluation starting in 2015-2023 (87,866 handlers x 108 months). Months with
# no evaluation carry zero counts and empty evaluation fields.
#
# An "evaluation" is one distinct combination of the RCRAInfo evaluation key
# (HANDLER_ID, EVAL_ACTIVITY_LOCATION, EVAL_IDENTIFIER, EVAL_START_DATE,
# EVAL_AGENCY); CE_MASTER repeats it across violation/enforcement/SEP/citation
# rows and it is collapsed back to one row here. Evaluations are assigned to
# the panel month by EVAL_START_DATE; records with a missing or unparseable
# start date cannot be month-assigned and are excluded.
#
# Columns
#   HANDLER_ID, FRS_ID, YEAR, MONTH
#   FRS_ID             EPA Facility Registry Service REGISTRY_ID, linked from
#                      the FRS Program Links file on the RCRAInfo Handler ID
#                      (PGM_SYS_ID where PGM_SYS_ACRNM == "RCRAINFO"); NA if
#                      no RCRAINFO link exists.
#   YEAR, MONTH        Panel index (2015-2023 x 1-12), the calendar year and
#                      month of EVAL_START_DATE for the row's evaluations.
#
#   Handler attributes (from the handler snapshot columns on the evaluation
#   records; constant within handler in the data except 18 handlers with two
#   HANDLER_ACTIVITY_LOCATION values, so the value on the handler's most
#   recent evaluation is used and repeated across all 108 months):
#     CE_ACTIVITY_STATE  <- HANDLER_ACTIVITY_LOCATION
#     CE_LOCATION_STATE  <- STATE
#     CE_EPA_REGION      <- REGION
#     CE_LAND_TYPE       <- LAND_TYPE (last non-missing; ~4.5% of evaluation
#                           records leave it blank)
#
#   Evaluation fields (month-level; empty when the month has no evaluation;
#   8.6% of evaluation months hold >1 evaluation, so multi-valued fields are
#   ";"-joined):
#     CE_EVAL_STATE      <- EVAL_ACTIVITY_LOCATION, distinct values in
#                           evaluation start-date order
#     CE_EVAL_AGENCY     <- EVAL_AGENCY, distinct values in start-date order
#     CE_EVAL_RESP_PERSON<- EVAL_RESPONSIBLE_PERSON, distinct codes in start-date
#                           order (blank on ~12.8% of evaluations)
#     CE_EVAL_SUBORG     <- EVAL_SUBORGANIZATION, distinct codes, each prefixed
#                           with its own evaluation state as STATE-SUBORG (e.g.
#                           IL-CD); blank on the ~35.6% of evaluations that carry
#                           no suborganization code
#     CE_EVAL_LAST_CHANGE<- max EVAL_LAST_CHANGE over the month's evaluations (the
#                           most recent evaluation-record change stamp)
#     CE_END_YEAR        <- year(NOC_DATE), one entry per evaluation in the
#     CE_END_MONTH       <- month(NOC_DATE) month that carries a notice-of-
#                           compliance date (~2.6% of evaluations do), joined
#                           in start-date order; the i-th CE_END_YEAR entry
#                           pairs with the i-th CE_END_MONTH entry.
#
#   Counts and indicators (0 on months with no evaluation; CE_ANY_* = 1 if
#   the matching CE_TOTAL_* / CE_EVALS_WITH_VIOL > 0, else 0):
#     CE_ANY_EVAL,  CE_TOTAL_EVALS   all evaluations starting in the month
#     CE_ANY_CEI,   CE_TOTAL_CEI     EVAL_TYPE == "CEI" (compliance evaluation
#                                    inspection)
#     CE_ANY_NRR,   CE_TOTAL_NRR     EVAL_TYPE == "NRR" (non-financial record
#                                    review)
#     CE_ANY_FCI,   CE_TOTAL_FCI     EVAL_TYPE == "FCI" (focused compliance
#                                    inspection)
#     CE_ANY_FRR,   CE_TOTAL_FRR     EVAL_TYPE == "FRR" (financial record
#                                    review)
#     CE_ANY_FSD,   CE_TOTAL_FSD     EVAL_TYPE == "FSD" (facility self
#                                    disclosure)
#     CE_ANY_OTHER, CE_TOTAL_OTHER   every other EVAL_TYPE (SNY, SNN, FUI,
#                                    CSE, CDI, CAV, OAM, CAC, GME, NIR)
#     CE_ANY_VIOL,  CE_EVALS_WITH_VIOL
#                                    evaluations with FOUND_VIOLATION == "Y";
#                                    "N" and "U" (undetermined) do not count.
#
#   Evaluation attribute indicators (0 on months with no evaluation; 1 when any
#   evaluation in the month carries the Y/N attribute as "Y", else 0):
#     CE_ANY_CITIZEN_COMPLAINT      <- CITIZEN_COMPLAINT     (~2.6% "Y")
#     CE_ANY_MULTIMEDIA_INSPECTION  <- MULTIMEDIA_INSPECTION (~2.6% "Y")
#     CE_ANY_SAMPLING               <- SAMPLING              (~0.2% "Y")
#     CE_ANY_NOT_SUBTITLE_C         <- NOT_SUBTITLE_C        (~0.1% "Y")
#
# Requires: tidyverse (incl. lubridate)
# =============================================================================

# Shared panel helpers: join_distinct(), last_known(), read_frs_links(),
# write_panel(). Loads tidyverse.
source("code/modules/03_panels/rcrainfo/00_panel_functions.R")

ce_file  <- "output/modular_master_files/CE_MASTER.csv"
frs_file <- "data/frs/FRS_PROGRAM_LINKS.csv"
out_file <- "output/panels/CE_PANEL_2015_2023/EVAL_PANEL_2015_2023.csv"
years    <- 2015L:2023L

typed <- c("CEI", "NRR", "FCI", "FRR", "FSD")   # own count columns; rest -> OTHER

# -- 1. CE_MASTER -> one row per evaluation, month-assigned --------------------
evals <- read_csv(ce_file, col_types = cols(.default = "c"), show_col_types = FALSE,
                  col_select = c(HANDLER_ID, EVAL_ACTIVITY_LOCATION, EVAL_IDENTIFIER,
                                 EVAL_START_DATE, EVAL_AGENCY, EVAL_TYPE,
                                 FOUND_VIOLATION, NOC_DATE,
                                 CITIZEN_COMPLAINT, MULTIMEDIA_INSPECTION, SAMPLING,
                                 NOT_SUBTITLE_C, EVAL_RESPONSIBLE_PERSON,
                                 EVAL_SUBORGANIZATION, EVAL_LAST_CHANGE,
                                 HANDLER_ACTIVITY_LOCATION, STATE, REGION, LAND_TYPE)) |>
  distinct(HANDLER_ID, EVAL_ACTIVITY_LOCATION, EVAL_IDENTIFIER, EVAL_START_DATE,
           EVAL_AGENCY, .keep_all = TRUE) |>
  mutate(start = ymd(EVAL_START_DATE, quiet = TRUE)) |>
  filter(!is.na(start), year(start) %in% years) |>
  # Suborganization carries its own evaluation state as a "STATE-SUBORG" prefix
  # (e.g. IL-CD); blank when the record has no suborganization code.
  mutate(YEAR  = year(start),
         MONTH = month(start),
         noc   = ymd(NOC_DATE, quiet = TRUE),
         EVAL_SUBORG = if_else(!is.na(EVAL_SUBORGANIZATION) & EVAL_SUBORGANIZATION != "",
                               paste(EVAL_ACTIVITY_LOCATION, EVAL_SUBORGANIZATION, sep = "-"),
                               NA_character_))

# -- 2. Facility-month aggregates ----------------------------------------------
agg <- evals |>
  arrange(HANDLER_ID, start) |>
  group_by(HANDLER_ID, YEAR, MONTH) |>
  summarise(
    CE_EVAL_STATE       = join_distinct(EVAL_ACTIVITY_LOCATION),
    CE_EVAL_AGENCY      = join_distinct(EVAL_AGENCY),
    CE_EVAL_RESP_PERSON = join_distinct(EVAL_RESPONSIBLE_PERSON),
    CE_EVAL_SUBORG      = join_distinct(EVAL_SUBORG),
    CE_END_YEAR         = paste(year(noc[!is.na(noc)]),  collapse = ";"),
    CE_END_MONTH        = paste(month(noc[!is.na(noc)]), collapse = ";"),
    CE_TOTAL_EVALS      = n(),
    CE_TOTAL_CEI        = sum(EVAL_TYPE == "CEI", na.rm = TRUE),
    CE_TOTAL_NRR        = sum(EVAL_TYPE == "NRR", na.rm = TRUE),
    CE_TOTAL_FCI        = sum(EVAL_TYPE == "FCI", na.rm = TRUE),
    CE_TOTAL_FRR        = sum(EVAL_TYPE == "FRR", na.rm = TRUE),
    CE_TOTAL_FSD        = sum(EVAL_TYPE == "FSD", na.rm = TRUE),
    CE_TOTAL_OTHER      = sum(!EVAL_TYPE %in% typed, na.rm = TRUE),
    CE_EVALS_WITH_VIOL  = sum(FOUND_VIOLATION == "Y", na.rm = TRUE),
    CE_ANY_CITIZEN_COMPLAINT     = as.integer(any(CITIZEN_COMPLAINT     == "Y", na.rm = TRUE)),
    CE_ANY_MULTIMEDIA_INSPECTION = as.integer(any(MULTIMEDIA_INSPECTION == "Y", na.rm = TRUE)),
    CE_ANY_SAMPLING              = as.integer(any(SAMPLING              == "Y", na.rm = TRUE)),
    CE_ANY_NOT_SUBTITLE_C        = as.integer(any(NOT_SUBTITLE_C        == "Y", na.rm = TRUE)),
    CE_EVAL_LAST_CHANGE = {v <- EVAL_LAST_CHANGE[!is.na(EVAL_LAST_CHANGE)]
                           if (length(v)) max(v) else NA_character_},
    .groups = "drop")

# -- 3. Handler attributes (most recent evaluation's snapshot) ------------------
attrs <- evals |>
  arrange(HANDLER_ID, start) |>
  group_by(HANDLER_ID) |>
  summarise(CE_ACTIVITY_STATE = last_known(HANDLER_ACTIVITY_LOCATION),
            CE_LOCATION_STATE = last_known(STATE),
            CE_EPA_REGION     = last_known(REGION),
            CE_LAND_TYPE      = last_known(LAND_TYPE),
            .groups = "drop")

# -- 4. FRS: Facility Registry Service ID ---------------------------------------
# Same link as the BR panels (see read_frs_links() in 00_panel_functions.R).
ids <- unique(evals$HANDLER_ID)
frs <- read_frs_links(ids, frs_file)

# -- 5. Balanced grid, assemble, write ------------------------------------------
# expand_grid() emits rows already sorted HANDLER_ID x YEAR x MONTH and the
# left joins preserve that order, so no final arrange over 9.5M rows is needed.
out <- expand_grid(HANDLER_ID = sort(ids), YEAR = years, MONTH = 1:12) |>
  left_join(frs,   by = "HANDLER_ID") |>
  left_join(attrs, by = "HANDLER_ID") |>
  left_join(agg,   by = c("HANDLER_ID", "YEAR", "MONTH")) |>
  mutate(across(c(starts_with("CE_TOTAL_"), CE_EVALS_WITH_VIOL,
                  CE_ANY_CITIZEN_COMPLAINT, CE_ANY_MULTIMEDIA_INSPECTION,
                  CE_ANY_SAMPLING, CE_ANY_NOT_SUBTITLE_C),
                \(x) replace_na(x, 0L)),
         CE_ANY_EVAL  = as.integer(CE_TOTAL_EVALS > 0),
         CE_ANY_CEI   = as.integer(CE_TOTAL_CEI   > 0),
         CE_ANY_NRR   = as.integer(CE_TOTAL_NRR   > 0),
         CE_ANY_FCI   = as.integer(CE_TOTAL_FCI   > 0),
         CE_ANY_FRR   = as.integer(CE_TOTAL_FRR   > 0),
         CE_ANY_FSD   = as.integer(CE_TOTAL_FSD   > 0),
         CE_ANY_OTHER = as.integer(CE_TOTAL_OTHER > 0),
         CE_ANY_VIOL  = as.integer(CE_EVALS_WITH_VIOL > 0)) |>
  select(HANDLER_ID, FRS_ID, YEAR, MONTH,
         CE_ACTIVITY_STATE, CE_LOCATION_STATE, CE_EPA_REGION, CE_LAND_TYPE,
         CE_EVAL_STATE, CE_EVAL_AGENCY, CE_EVAL_RESP_PERSON, CE_EVAL_SUBORG,
         CE_END_YEAR, CE_END_MONTH,
         CE_ANY_EVAL,  CE_TOTAL_EVALS,
         CE_ANY_CEI,   CE_TOTAL_CEI,
         CE_ANY_NRR,   CE_TOTAL_NRR,
         CE_ANY_FCI,   CE_TOTAL_FCI,
         CE_ANY_FRR,   CE_TOTAL_FRR,
         CE_ANY_FSD,   CE_TOTAL_FSD,
         CE_ANY_OTHER, CE_TOTAL_OTHER,
         CE_ANY_VIOL,  CE_EVALS_WITH_VIOL,
         CE_ANY_CITIZEN_COMPLAINT, CE_ANY_MULTIMEDIA_INSPECTION,
         CE_ANY_SAMPLING, CE_ANY_NOT_SUBTITLE_C,
         CE_EVAL_LAST_CHANGE)

# write_panel() writes the CSV plus an .rds twin: plain CSV stores no column
# types, so read_csv() re-guesses them and mistypes the sparse columns (the
# mostly-empty CE_END_YEAR reads as all-NA logical, and CE_EPA_REGION "05"
# loses its leading zero); the .rds copy preserves every column's type exactly.
write_panel(out, out_file, rds = TRUE)
