# =============================================================================
# 02_panel_eval_2015_2023.R
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
#     CE_ANY_SNY,   CE_TOTAL_SNY     EVAL_TYPE == "SNY" (significant non-
#                                    complier determination)
#     CE_ANY_CSE,   CE_TOTAL_CSE     EVAL_TYPE == "CSE" (compliance schedule
#                                    evaluation)
#     CE_ANY_OTHER, CE_TOTAL_OTHER   every other EVAL_TYPE (FRR, FSD, SNN,
#                                    FUI, CAV, CDI, OAM, CAC, GME, NIR)
#     CE_ANY_VIOL,  CE_EVALS_WITH_VIOL
#                                    evaluations with FOUND_VIOLATION == "Y";
#                                    "N" and "U" (undetermined) do not count.
#
# Requires: tidyverse (incl. lubridate)
# =============================================================================

library(tidyverse)

ce_file  <- "output/modular_master_files/CE_MASTER.csv"
frs_file <- "data/frs/FRS_PROGRAM_LINKS.csv"
out_file <- "output/panels/CE_PANEL_2015_2023.csv"
years    <- 2015L:2023L

typed <- c("CEI", "NRR", "FCI", "SNY", "CSE")   # own count columns; rest -> OTHER

last_known <- function(x) {                     # last non-missing, else NA
  x <- x[!is.na(x)]
  if (length(x)) x[length(x)] else NA_character_
}

# -- 1. CE_MASTER -> one row per evaluation, month-assigned --------------------
evals <- read_csv(ce_file, col_types = cols(.default = "c"), show_col_types = FALSE,
                  col_select = c(HANDLER_ID, EVAL_ACTIVITY_LOCATION, EVAL_IDENTIFIER,
                                 EVAL_START_DATE, EVAL_AGENCY, EVAL_TYPE,
                                 FOUND_VIOLATION, NOC_DATE,
                                 HANDLER_ACTIVITY_LOCATION, STATE, REGION, LAND_TYPE)) |>
  distinct(HANDLER_ID, EVAL_ACTIVITY_LOCATION, EVAL_IDENTIFIER, EVAL_START_DATE,
           EVAL_AGENCY, .keep_all = TRUE) |>
  mutate(start = ymd(EVAL_START_DATE, quiet = TRUE)) |>
  filter(!is.na(start), year(start) %in% years) |>
  mutate(YEAR  = year(start),
         MONTH = month(start),
         noc   = ymd(NOC_DATE, quiet = TRUE))

# -- 2. Facility-month aggregates ----------------------------------------------
agg <- evals |>
  arrange(HANDLER_ID, start) |>
  group_by(HANDLER_ID, YEAR, MONTH) |>
  summarise(
    CE_EVAL_STATE      = paste(unique(EVAL_ACTIVITY_LOCATION), collapse = ";"),
    CE_EVAL_AGENCY     = paste(unique(EVAL_AGENCY), collapse = ";"),
    CE_END_YEAR        = paste(year(noc[!is.na(noc)]),  collapse = ";"),
    CE_END_MONTH       = paste(month(noc[!is.na(noc)]), collapse = ";"),
    CE_TOTAL_EVALS     = n(),
    CE_TOTAL_CEI       = sum(EVAL_TYPE == "CEI", na.rm = TRUE),
    CE_TOTAL_NRR       = sum(EVAL_TYPE == "NRR", na.rm = TRUE),
    CE_TOTAL_FCI       = sum(EVAL_TYPE == "FCI", na.rm = TRUE),
    CE_TOTAL_SNY       = sum(EVAL_TYPE == "SNY", na.rm = TRUE),
    CE_TOTAL_CSE       = sum(EVAL_TYPE == "CSE", na.rm = TRUE),
    CE_TOTAL_OTHER     = sum(!EVAL_TYPE %in% typed, na.rm = TRUE),
    CE_EVALS_WITH_VIOL = sum(FOUND_VIOLATION == "Y", na.rm = TRUE),
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
# Same link as the BR panel: RCRAInfo Handler ID against PGM_SYS_ID on the
# RCRAINFO program rows; PGM_SYS_ID -> REGISTRY_ID is 1:1 there, so the join
# below does not fan out the panel.
ids <- unique(evals$HANDLER_ID)
frs <- read_csv(frs_file, col_types = cols(.default = "c"), show_col_types = FALSE,
                col_select = c(PGM_SYS_ACRNM, PGM_SYS_ID, REGISTRY_ID)) |>
  filter(PGM_SYS_ACRNM == "RCRAINFO", PGM_SYS_ID %in% ids) |>
  distinct(HANDLER_ID = PGM_SYS_ID, FRS_ID = REGISTRY_ID)

# -- 5. Balanced grid, assemble, write ------------------------------------------
# expand_grid() emits rows already sorted HANDLER_ID x YEAR x MONTH and the
# left joins preserve that order, so no final arrange over 9.5M rows is needed.
out <- expand_grid(HANDLER_ID = sort(ids), YEAR = years, MONTH = 1:12) |>
  left_join(frs,   by = "HANDLER_ID") |>
  left_join(attrs, by = "HANDLER_ID") |>
  left_join(agg,   by = c("HANDLER_ID", "YEAR", "MONTH")) |>
  mutate(across(c(starts_with("CE_TOTAL_"), CE_EVALS_WITH_VIOL),
                \(x) replace_na(x, 0L)),
         CE_ANY_EVAL  = as.integer(CE_TOTAL_EVALS > 0),
         CE_ANY_CEI   = as.integer(CE_TOTAL_CEI   > 0),
         CE_ANY_NRR   = as.integer(CE_TOTAL_NRR   > 0),
         CE_ANY_FCI   = as.integer(CE_TOTAL_FCI   > 0),
         CE_ANY_SNY   = as.integer(CE_TOTAL_SNY   > 0),
         CE_ANY_CSE   = as.integer(CE_TOTAL_CSE   > 0),
         CE_ANY_OTHER = as.integer(CE_TOTAL_OTHER > 0),
         CE_ANY_VIOL  = as.integer(CE_EVALS_WITH_VIOL > 0)) |>
  select(HANDLER_ID, FRS_ID, YEAR, MONTH,
         CE_ACTIVITY_STATE, CE_LOCATION_STATE, CE_EPA_REGION, CE_LAND_TYPE,
         CE_EVAL_STATE, CE_EVAL_AGENCY, CE_END_YEAR, CE_END_MONTH,
         CE_ANY_EVAL,  CE_TOTAL_EVALS,
         CE_ANY_CEI,   CE_TOTAL_CEI,
         CE_ANY_NRR,   CE_TOTAL_NRR,
         CE_ANY_FCI,   CE_TOTAL_FCI,
         CE_ANY_SNY,   CE_TOTAL_SNY,
         CE_ANY_CSE,   CE_TOTAL_CSE,
         CE_ANY_OTHER, CE_TOTAL_OTHER,
         CE_ANY_VIOL,  CE_EVALS_WITH_VIOL)

dir.create(dirname(out_file), showWarnings = FALSE, recursive = TRUE)
write_csv(out, out_file, na = "")
