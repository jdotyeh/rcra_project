# =============================================================================
# FILE:     04_panel_enf_2015_2023.R
# PURPOSE:  Build the balanced facility-month panel of RCRA enforcement actions
#           from CE_MASTER, months 2015-01 through 2023-12, with the FRS link.
# INPUTS:   output/modular_master_files/CE_MASTER.csv,
#           data/frs/FRS_PROGRAM_LINKS.csv; sources 00_panel_functions.R
# OUTPUTS:  output/panels/CE_PANEL_2015_2023/ENF_PANEL_2015_2023.csv
#           (+ .rds twin with exact column types)
# AUTHOR:   Jason Ye
# CREATED:  2026-07-16
# UPDATED:  2026-07-16
# =============================================================================
#
# Facility-month panel of RCRA enforcement actions built from CE_MASTER,
# calendar months 2015-01 through 2023-12. One row per handler x year x month,
# balanced over the full 108-month window for every handler with at least one
# enforcement action dated 2015-2023 (32,172 handlers x 108 months). Months with
# no action carry zero counts and empty enforcement fields.
#
# An "enforcement action" is one distinct combination of the RCRAInfo
# enforcement key (HANDLER_ID, ENF_ACTIVITY_LOCATION, ENF_IDENTIFIER,
# ENF_ACTION_DATE, ENF_AGENCY). CE_MASTER repeats the action across its
# evaluation, violation, citation and SEP rows, and it is collapsed back to one
# row here; ENF_TYPE and the other action attributes are constant within the
# key. Each action is assigned to the panel month of ENF_ACTION_DATE, which is
# populated and parseable on every enforcement record in the data, so no action
# is dropped for a missing date.
#
# Columns
#   HANDLER_ID, FRS_ID, YEAR, MONTH
#   FRS_ID             EPA Facility Registry Service REGISTRY_ID, linked from the
#                      FRS Program Links file on the RCRAInfo Handler ID
#                      (PGM_SYS_ID where PGM_SYS_ACRNM == "RCRAINFO"); NA when no
#                      RCRAINFO link exists.
#   YEAR, MONTH        Panel index (2015-2023 x 1-12), the calendar year and
#                      month of ENF_ACTION_DATE for the row's actions.
#
#   Handler attributes (from the handler snapshot columns on the enforcement
#   records; the value on the handler's most recent action is used and repeated
#   across all 108 months):
#     CE_ACTIVITY_STATE  <- HANDLER_ACTIVITY_LOCATION
#     CE_LOCATION_STATE  <- STATE
#     CE_EPA_REGION      <- REGION
#     CE_LAND_TYPE       <- LAND_TYPE (last non-missing)
#
#   Enforcement fields (month level; empty when the month has no action; 6.8% of
#   active months hold more than one action, so multi-valued string fields carry
#   the distinct values in action-date order, joined with ";"):
#     CE_ENF_STATE       <- ENF_ACTIVITY_LOCATION, the state whose agency issued
#                           the action.
#     CE_ENF_TYPE        <- ENF_TYPE, the distinct enforcement type codes that
#                           are nationally defined (one of the 37 codes in
#                           resources CME-Enforcement-Type; sorted).
#     CE_ENF_TYPE_UNDEFINED <- ENF_TYPE, the distinct codes that are NOT
#                           nationally defined (state-specific codes such as 125,
#                           124, 122; sorted). CE_ENF_TYPE and this field
#                           partition the month's type codes.
#     CE_ENF_TYPE_NUM    Count of distinct ENF_TYPE codes in the month, defined
#                           and undefined together.
#     CE_DOCKET          <- DOCKET_NUMBER
#     CE_ATTORNEY        <- ATTORNEY
#     CE_ENF_RESP_PERSON <- ENF_RESPONSIBLE_PERSON
#     CE_ENF_SUBORG      <- ENF_SUBORGANIZATION, each code prefixed with its own
#                           enforcement state as STATE-SUBORG (e.g. IL-CD)
#     CE_DISP_STATUS     <- DISPOSITION_STATUS, distinct disposition codes.
#     CE_DISP_DATE       <- DISPOSITION_STATUS_DATE, distinct disposition dates.
#                           The disposition describes how an action ISSUED in the
#                           month was later closed, so its date can fall in a
#                           later month than the row; status and date are each
#                           deduplicated independently and are not positionally
#                           paired.
#     CE_CAFO_RESPONDENT <- RESPONDENT_NAME (CA/FO respondent)
#     CE_CAFO_LEAD_AGENCY<- LEAD_AGENCY (CA/FO lead agency)
#     CE_ENF_LAST_CHANGE <- max ENF_LAST_CHANGE over the month's actions (the
#                           most recent enforcement record change stamp).
#
#   Counts and indicators (0 on months with no action; CE_ANY_* = 1 when the
#   matching count is > 0, else 0):
#     CE_ANY_ENF,       CE_TOTAL_ENF        all enforcement actions in the month
#     CE_ANY_STATE_ENF, CE_TOTAL_STATE_ENF  ENF_AGENCY == "S" (state issued)
#     CE_ANY_FED_ENF,   CE_TOTAL_FED_ENF    ENF_AGENCY == "E" (EPA/federal issued)
#     CE_ANY_CA_COMPONENT   1 if any action in the month has CA_COMPONENT == "Y"
#                           (corrective-action component), else 0.
#     CE_ANY_FA_REQUIREMENT 1 if any action in the month has FA_REQUIREMENT ==
#                           "Y" (financial-assurance requirement), else 0.
#
# Enforcement responsible agency is "S" or "E" for every action in the window,
# so the state/federal split is exhaustive; any other agency code, if it ever
# appears, counts toward neither state nor federal.
#
# Requires: tidyverse (incl. lubridate)
# =============================================================================

# Shared panel helpers: join_distinct(), last_known(), read_frs_links(),
# write_panel(). Loads tidyverse.
source("code/modules/03_panels/rcrainfo/00_panel_functions.R")

ce_file  <- "output/modular_master_files/CE_MASTER.csv"
frs_file <- "data/frs/FRS_PROGRAM_LINKS.csv"
out_file <- "output/panels/CE_PANEL_2015_2023/ENF_PANEL_2015_2023.csv"
years    <- 2015L:2023L

# The 37 nationally-defined RCRAInfo enforcement-type codes (resources
# CME-Enforcement-Type.md). Membership is the whole defined/undefined rule: the
# cleaned reference in /Users/junliangye/Misc reproduces exactly to this set.
enf_type_national <- c(
  "110", "120", "130", "140", "210", "220", "230", "240", "250", "305",
  "310", "320", "330", "340", "380", "385", "410", "420", "425", "430",
  "510", "520", "530", "610", "620", "630", "710", "720", "730", "740",
  "810", "820", "830", "840", "850", "860", "865")

# -- 1. CE_MASTER -> one row per enforcement action, month-assigned -------------
key <- c("HANDLER_ID", "ENF_ACTIVITY_LOCATION", "ENF_IDENTIFIER",
         "ENF_ACTION_DATE", "ENF_AGENCY")

acts <- read_csv(ce_file, col_types = cols(.default = "c"), show_col_types = FALSE,
                 col_select = c(all_of(key), ENF_TYPE, DOCKET_NUMBER, ATTORNEY,
                                ENF_RESPONSIBLE_PERSON, ENF_SUBORGANIZATION,
                                CA_COMPONENT, FA_REQUIREMENT, DISPOSITION_STATUS,
                                DISPOSITION_STATUS_DATE, RESPONDENT_NAME,
                                LEAD_AGENCY, ENF_LAST_CHANGE,
                                HANDLER_ACTIVITY_LOCATION, STATE, REGION, LAND_TYPE)) |>
  filter(!(is.na(ENF_IDENTIFIER) & is.na(ENF_ACTION_DATE) &
             is.na(ENF_AGENCY) & is.na(ENF_TYPE))) |>
  distinct(across(all_of(key)), .keep_all = TRUE) |>
  mutate(action = ymd(ENF_ACTION_DATE, quiet = TRUE)) |>
  filter(!is.na(action), year(action) %in% years) |>
  # Suborganization carries its own enforcement state as a "STATE-SUBORG" prefix
  # (e.g. IL-CD); blank when the record has no suborganization code.
  mutate(YEAR  = year(action),
         MONTH = month(action),
         is_defined = ENF_TYPE %in% enf_type_national,
         ENF_SUBORG = if_else(!is.na(ENF_SUBORGANIZATION) & ENF_SUBORGANIZATION != "",
                              paste(ENF_ACTIVITY_LOCATION, ENF_SUBORGANIZATION, sep = "-"),
                              NA_character_))

ids <- sort(unique(acts$HANDLER_ID))

# -- 2. Facility-month aggregates ----------------------------------------------
agg <- acts |>
  arrange(HANDLER_ID, action) |>
  group_by(HANDLER_ID, YEAR, MONTH) |>
  summarise(
    CE_ENF_STATE          = join_distinct(ENF_ACTIVITY_LOCATION),
    CE_ENF_TYPE           = paste(sort(unique(ENF_TYPE[is_defined])),  collapse = ";"),
    CE_ENF_TYPE_UNDEFINED = paste(sort(unique(ENF_TYPE[!is_defined & !is.na(ENF_TYPE)])),
                                  collapse = ";"),
    CE_ENF_TYPE_NUM       = n_distinct(ENF_TYPE[!is.na(ENF_TYPE)]),
    CE_DOCKET             = join_distinct(DOCKET_NUMBER),
    CE_ATTORNEY           = join_distinct(ATTORNEY),
    CE_ENF_RESP_PERSON    = join_distinct(ENF_RESPONSIBLE_PERSON),
    CE_ENF_SUBORG         = join_distinct(ENF_SUBORG),
    CE_DISP_STATUS        = join_distinct(DISPOSITION_STATUS),
    CE_DISP_DATE          = join_distinct(DISPOSITION_STATUS_DATE),
    CE_CAFO_RESPONDENT    = join_distinct(RESPONDENT_NAME),
    CE_CAFO_LEAD_AGENCY   = join_distinct(LEAD_AGENCY),
    CE_ENF_LAST_CHANGE    = {v <- ENF_LAST_CHANGE[!is.na(ENF_LAST_CHANGE)]
                             if (length(v)) max(v) else NA_character_},
    CE_TOTAL_ENF          = n(),
    CE_TOTAL_STATE_ENF    = sum(ENF_AGENCY == "S", na.rm = TRUE),
    CE_TOTAL_FED_ENF      = sum(ENF_AGENCY == "E", na.rm = TRUE),
    CE_ANY_CA_COMPONENT   = as.integer(any(CA_COMPONENT   == "Y", na.rm = TRUE)),
    CE_ANY_FA_REQUIREMENT = as.integer(any(FA_REQUIREMENT == "Y", na.rm = TRUE)),
    .groups = "drop")

# -- 3. Handler attributes (most recent action's snapshot) ---------------------
attrs <- acts |>
  arrange(HANDLER_ID, action) |>
  group_by(HANDLER_ID) |>
  summarise(CE_ACTIVITY_STATE = last_known(HANDLER_ACTIVITY_LOCATION),
            CE_LOCATION_STATE = last_known(STATE),
            CE_EPA_REGION     = last_known(REGION),
            CE_LAND_TYPE      = last_known(LAND_TYPE),
            .groups = "drop")

# -- 4. FRS: Facility Registry Service ID ---------------------------------------
# Same link as the other panels (see read_frs_links() in 00_panel_functions.R).
frs <- read_frs_links(ids, frs_file)

# -- 5. Balanced grid, assemble, write ------------------------------------------
# expand_grid() emits rows already sorted HANDLER_ID x YEAR x MONTH and the left
# joins preserve that order, so no final arrange over the 3.5M rows is needed.
count_cols <- c("CE_ENF_TYPE_NUM", "CE_TOTAL_ENF", "CE_TOTAL_STATE_ENF",
                "CE_TOTAL_FED_ENF", "CE_ANY_CA_COMPONENT", "CE_ANY_FA_REQUIREMENT")

out <- expand_grid(HANDLER_ID = ids, YEAR = years, MONTH = 1:12) |>
  left_join(frs,   by = "HANDLER_ID") |>
  left_join(attrs, by = "HANDLER_ID") |>
  left_join(agg,   by = c("HANDLER_ID", "YEAR", "MONTH")) |>
  mutate(across(all_of(count_cols), \(x) replace_na(x, 0L)),
         CE_ANY_ENF       = as.integer(CE_TOTAL_ENF       > 0),
         CE_ANY_STATE_ENF = as.integer(CE_TOTAL_STATE_ENF > 0),
         CE_ANY_FED_ENF   = as.integer(CE_TOTAL_FED_ENF   > 0)) |>
  select(HANDLER_ID, FRS_ID, YEAR, MONTH,
         CE_ACTIVITY_STATE, CE_LOCATION_STATE, CE_EPA_REGION, CE_LAND_TYPE,
         CE_ENF_STATE,
         CE_ANY_ENF,       CE_TOTAL_ENF,
         CE_ANY_STATE_ENF, CE_TOTAL_STATE_ENF,
         CE_ANY_FED_ENF,   CE_TOTAL_FED_ENF,
         CE_ENF_TYPE_NUM,  CE_ENF_TYPE, CE_ENF_TYPE_UNDEFINED,
         CE_ANY_CA_COMPONENT, CE_ANY_FA_REQUIREMENT,
         CE_DOCKET, CE_ATTORNEY, CE_ENF_RESP_PERSON, CE_ENF_SUBORG,
         CE_DISP_STATUS, CE_DISP_DATE,
         CE_CAFO_RESPONDENT, CE_CAFO_LEAD_AGENCY, CE_ENF_LAST_CHANGE)

# write_panel() writes the CSV plus an .rds twin: plain CSV stores no column
# types, so read_csv() re-guesses them and mistypes the sparse columns (the
# mostly-empty CE_DISP_STATUS reads as all-NA logical, and CE_EPA_REGION "05"
# loses its leading zero); the .rds copy preserves every column's type exactly.
write_panel(out, out_file, rds = TRUE)
