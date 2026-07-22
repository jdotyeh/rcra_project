# =============================================================================
# FILE:     04_panel_enf_2015_2023.R
# PURPOSE:  Build the balanced facility-month panel of RCRA enforcement actions
#           from CE_MASTER, months 2015-01 through 2023-12, with the FRS link.
# INPUTS:   output/modular_master_files/CE_MASTER.csv,
#           output/modular_master_files/HD_MASTER.csv (coordinate slots only),
#           resources/CE-Enforcement-Type.md,
#           resources/CE-Enforcement-Type-Crosswalk.md,
#           data/frs/FRS_PROGRAM_LINKS.csv; sources 00_panel_functions.R
# OUTPUTS:  output/panels/CE_PANEL_2015_2023/ENF_PANEL_2015_2023.csv
#           (+ .rds twin with exact column types)
# AUTHOR:   Jason Ye
# CREATED:  2026-07-16
# UPDATED:  2026-07-21
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
#   Coordinate slots (from HD_MASTER, one block per facility repeated across
#   all 108 months, taken from the handler's most recent handler record):
#     HD_PREFERRED_LATITUDE, HD_PREFERRED_LONGITUDE, HD_PREFERRED_COORD_SOURCE
#                        The pair to use and where it came from, which is the
#                        hand-placed pair, else the FRS pair, else the pair the
#                        record reported, else a pair another record of the same
#                        handler reported ("MANUAL", "FRS", "HD", "HD_OTHER").
#     HD_LATITUDE_2-5, HD_LONGITUDE_2-5, HD_COORD_SOURCE_2-5
#                        The pairs the preference order set aside, so a facility
#                        whose sources disagree can be seen to. Empty where the
#                        facility has no further pair. The ranking is documented
#                        in the 02_modular_master_files README.
#
#   Enforcement fields (month level; empty when the month has no action; 6.8% of
#   active months hold more than one action, so multi-valued string fields carry
#   the distinct values in action-date order, joined with ";"):
#     CE_ENF_STATE       <- ENF_ACTIVITY_LOCATION, the state whose agency issued
#                           the action.
#     CE_ENF_FORMAL      1 if any action in the month carries a formal recoded
#                           type (any defined code from 210 upward), else 0, and
#                           0 on months with no action.
#     CE_ENF_INFORMAL    1 if any action in the month carries an informal
#                           recoded type (110, 120, 130, or 140), else 0. A month
#                           can set both indicators, and sets neither when no
#                           action in it is classified. A pair left at 999 is
#                           normally unclassified, but takes the class the
#                           crosswalk read off its own description on the nine
#                           pairs where the description settles it. The split
#                           follows the code band rather than the reference
#                           table's "Formal Action" column, which marks the
#                           narrower set of actions that count as addressing a
#                           significant non-complier.
#     CE_ENF_TYPE        <- ENF_TYPE recoded, the distinct nationally-defined
#                           codes in the month (sorted). An action whose code is
#                           already one of the 37 defined codes keeps it; a
#                           state-specific code takes the defined code its
#                           description was matched to in the crosswalk in
#                           resources CE-Enforcement-Type-Crosswalk.md. Pairs the
#                           crosswalk matches to 999, meaning no defined code
#                           covers them, are left out of this field.
#     CE_ENF_SUBTYPE     <- ENF_TYPE, the distinct codes that are NOT nationally
#                           defined (state-specific codes such as 125, 124, 122;
#                           sorted), carried exactly as the states wrote them and
#                           unaffected by the recode, so the original value stays
#                           recoverable alongside the recoded one. The name reads
#                           these codes for what they are, a state's own
#                           subdivision of the national type it recodes to.
#     CE_ENF_TYPE_DESC   <- ENF_TYPE_DESC, the type descriptions in action-date
#                           order. A defined code takes its name from the
#                           reference table in resources CE-Enforcement-Type.md,
#                           which also fills the records that carry no description
#                           of their own; a state-specific code takes the
#                           crosswalk's revised reading of what the state wrote,
#                           including on the pairs that recode to 999. The revised
#                           reading is title-cased, has its abbreviations
#                           expanded, and carries no comma; the state's raw string
#                           is recoverable by taking CE_ENF_SUBTYPE back to the
#                           crosswalk.
#     CE_ENF_CATEGORY    <- ENF_TYPE, the distinct proposed categories on the
#                           month's actions (sorted). The categories are the 900
#                           block defined in the crosswalk, which separates
#                           instruments the defined codes collapse together, so a
#                           warning letter and a notice of violation both matched
#                           to 120 read 901 and 902 here. Empty when no action in
#                           the month carries one, which is the case for every
#                           action whose code is already national.
#     CE_ENF_TYPE_NUM    Count of distinct ENF_TYPE codes in the month as they
#                           were recorded, defined and undefined together, so the
#                           recode does not change it.
#     CE_DOCKET          <- DOCKET_NUMBER
#     CE_ENF_SUBORG      <- ENF_SUBORGANIZATION, each code prefixed with its own
#                           enforcement state as STATE-SUBORG (e.g. IL-CD)
#
#   Counts and indicators (0 on months with no action; CE_ANY_* = 1 when the
#   matching count is > 0, else 0):
#     CE_ANY_ENF,       CE_TOTAL_ENF        all enforcement actions in the month
#     CE_ANY_STATE_ENF, CE_TOTAL_STATE_ENF  ENF_AGENCY == "S" (state issued)
#     CE_ANY_FED_ENF,   CE_TOTAL_FED_ENF    ENF_AGENCY == "E" (EPA/federal issued)
#
# Enforcement responsible agency is "S" or "E" for every action in the window,
# so the state/federal split is exhaustive; any other agency code, if it ever
# appears, counts toward neither state nor federal.
#
# Requires: tidyverse (incl. lubridate)
# =============================================================================

# Shared panel helpers: join_distinct(), last_known(), read_frs_links(),
# write_panel(), read_enf_type_defined(), read_enf_type_crosswalk(). Loads
# tidyverse.
source("code/modules/03_panels/rcrainfo/00_panel_functions.R")

# Inputs, output, and the panel year range.
ce_file  <- "output/modular_master_files/CE_MASTER.csv"
hd_file  <- "output/modular_master_files/HD_MASTER.csv"
frs_file <- "data/frs/FRS_PROGRAM_LINKS.csv"
out_file <- "output/panels/CE_PANEL_2015_2023/ENF_PANEL_2015_2023.csv"
years    <- 2015L:2023L

# The 37 nationally-defined enforcement types and their names, and the crosswalk
# that matches each state-specific code and description to a defined code. Both
# are read from their reference files in resources/ rather than being repeated
# here, so the files stay the single place either set is edited.
enf_defined <- read_enf_type_defined()
enf_xwalk   <- read_enf_type_crosswalk()
enf_categories    <- read_enf_type_categories()
enf_type_national <- enf_defined$ENF_TYPE

# The informal types are the four notification codes; every other defined code is
# a formal action. This split is taken from the code band and from the wording of
# the definitions, where 110 through 140 are notifications and 210 upward are
# orders, filings, and referrals. It is deliberately not taken from the reference
# table's "Formal Action" column, which marks the narrower set of actions that
# count as addressing a significant non-complier and therefore leaves several
# formal orders, including the criminal codes 710 through 740, flagged 0.
enf_type_informal <- c("110", "120", "130", "140")

# -- 1. CE_MASTER -> one row per enforcement action, month-assigned -------------
# RCRAInfo enforcement key: the five columns that uniquely identify an action.
key <- c("HANDLER_ID", "ENF_ACTIVITY_LOCATION", "ENF_IDENTIFIER",
         "ENF_ACTION_DATE", "ENF_AGENCY")

acts <- read_csv(ce_file, col_types = cols(.default = "c"), show_col_types = FALSE,
                 # Pull only the columns needed for the panel; the master file is
                 # wide, so restricting here saves memory.
                 col_select = c(all_of(key), ENF_TYPE, ENF_TYPE_DESC,
                                DOCKET_NUMBER, ENF_SUBORGANIZATION,
                                HANDLER_ACTIVITY_LOCATION, STATE, REGION, LAND_TYPE)) |>
  # Drop the sentinel evaluation rows that carry no enforcement fields.
  filter(!(is.na(ENF_IDENTIFIER) & is.na(ENF_ACTION_DATE) &
             is.na(ENF_AGENCY) & is.na(ENF_TYPE))) |>
  # Collapse the master's fanout down to one row per action.
  distinct(across(all_of(key)), .keep_all = TRUE) |>
  # Parse the action date and keep only actions dated in the panel window.
  mutate(action = ymd(ENF_ACTION_DATE, quiet = TRUE)) |>
  filter(!is.na(action), year(action) %in% years) |>
  # Suborganization carries its own enforcement state as a "STATE-SUBORG" prefix
  # (e.g. IL-CD); blank when the record has no suborganization code.
  mutate(YEAR  = year(action),
         MONTH = month(action),
         # Split the type into the defined and state-specific groups once here
         # so agg can partition on the flag.
         is_defined = ENF_TYPE %in% enf_type_national,
         # Normalise the description to the form the crosswalk is keyed on, with
         # a blank description read as missing so it matches the record's
         # "<no description>" rows.
         ENF_TYPE_DESC = na_if(str_squish(ENF_TYPE_DESC), ""),
         ENF_SUBORG = if_else(!is.na(ENF_SUBORGANIZATION) & ENF_SUBORGANIZATION != "",
                              paste(ENF_ACTIVITY_LOCATION, ENF_SUBORGANIZATION, sep = "-"),
                              NA_character_)) |>
  # Attach the defined code each state-specific code and description was matched
  # to, and the defined name for the codes that are already national. The join is
  # on the code and the description together, since a state code carries several
  # descriptions that were matched to different defined codes.
  left_join(enf_xwalk,   by = c("ENF_TYPE", "ENF_TYPE_DESC")) |>
  left_join(enf_defined, by = "ENF_TYPE") |>
  mutate(
    # The recoded type: a defined code keeps itself, a state-specific code takes
    # its matched code, and 999 marks a pair the crosswalk leaves unmatched or
    # does not list at all.
    ENF_TYPE_CODE = if_else(is_defined, ENF_TYPE, coalesce(ENF_TYPE_MAPPED, "999")),
    # The description: a defined code takes the name from the reference table,
    # which also fills the records that carry no description of their own, and a
    # state-specific code takes the crosswalk's revised reading of what the state
    # wrote, including on the pairs that recode to 999. The revised reading is
    # title-cased, has its abbreviations expanded, and carries no comma, so the
    # field can be split on the ";" join without ambiguity; the state's raw string
    # stays recoverable by taking CE_ENF_SUBTYPE back to the crosswalk.
    ENF_TYPE_LABEL = if_else(is_defined, ENF_TYPE_NAME, ENF_TYPE_REVISED),
    # Formal or informal. A recoded defined code settles the class on its own; a
    # pair left at 999 falls back to the class the crosswalk read off its
    # description, and stays unclassified where the description settles nothing.
    ENF_TYPE_CLASS = coalesce(
      case_when(ENF_TYPE_CODE == "999"              ~ NA_character_,
                ENF_TYPE_CODE %in% enf_type_informal ~ "informal",
                TRUE                                 ~ "formal"),
      ENF_TYPE_CLASS))

# Report any state-specific pair the crosswalk does not list, which falls to 999
# by default. A non-zero count means the reference record needs the pair added.
unlisted <- acts |>
  filter(!is_defined, is.na(ENF_TYPE_MAPPED)) |>
  distinct(ENF_TYPE, ENF_TYPE_DESC)
if (nrow(unlisted))
  message("Enforcement-type pairs missing from the crosswalk: ", nrow(unlisted))

# Sorted handler list defines the panel row space (used by expand_grid() below).
ids <- sort(unique(acts$HANDLER_ID))

# -- 2. Facility-month aggregates ----------------------------------------------
# Collapse to one row per (handler, year, month) with every action in the month
# rolled into a set of string, count, and indicator fields.
agg <- acts |>
  # Sort by action date so join_distinct() emits values in chronological order.
  arrange(HANDLER_ID, action) |>
  group_by(HANDLER_ID, YEAR, MONTH) |>
  summarise(
    # Distinct state issuers on the month's actions, action-date order.
    CE_ENF_STATE          = join_distinct(ENF_ACTIVITY_LOCATION),
    # Formal and informal indicators over the recoded types. A month can set both
    # when it holds actions of each kind, and sets neither when every action in it
    # recodes to 999.
    CE_ENF_FORMAL         = as.integer(any(ENF_TYPE_CLASS == "formal",   na.rm = TRUE)),
    CE_ENF_INFORMAL       = as.integer(any(ENF_TYPE_CLASS == "informal", na.rm = TRUE)),
    # Recoded defined codes, sorted for stability. 999 is left out, since a pair
    # that no defined code covers is already carried by the undefined field.
    CE_ENF_TYPE           = paste(sort(unique(ENF_TYPE_CODE[ENF_TYPE_CODE != "999"])),
                                  collapse = ";"),
    # The state-specific codes exactly as the states wrote them, unaffected by the
    # recode, so the original value stays recoverable.
    CE_ENF_SUBTYPE        = paste(sort(unique(ENF_TYPE[!is_defined & !is.na(ENF_TYPE)])),
                                  collapse = ";"),
    # Type descriptions in action-date order, the reference name for a defined
    # code and the crosswalk's revised reading for a state-specific one.
    CE_ENF_TYPE_DESC      = join_distinct(ENF_TYPE_LABEL),
    # Proposed categories on the month's actions, sorted. Empty when no action in
    # the month carries one, which is every action whose code is already national.
    CE_ENF_CATEGORY       = paste(sort(unique(ENF_TYPE_CATEGORY[!is.na(ENF_TYPE_CATEGORY)])),
                                  collapse = ";"),
    # Count of distinct type codes as they were recorded, across defined + undefined.
    CE_ENF_TYPE_NUM       = n_distinct(ENF_TYPE[!is.na(ENF_TYPE)]),
    # Other multi-valued string fields.
    CE_DOCKET             = join_distinct(DOCKET_NUMBER),
    CE_ENF_SUBORG         = join_distinct(ENF_SUBORG),
    # Counts: total, and the exhaustive state (S) / federal (E) split.
    CE_TOTAL_ENF          = n(),
    CE_TOTAL_STATE_ENF    = sum(ENF_AGENCY == "S", na.rm = TRUE),
    CE_TOTAL_FED_ENF      = sum(ENF_AGENCY == "E", na.rm = TRUE),
    .groups = "drop")

# -- 3. Handler attributes (most recent action's snapshot) ---------------------
# Repeat these attributes across all 108 months for the handler, using the
# value on the handler's most recent enforcement record.
attrs <- acts |>
  arrange(HANDLER_ID, action) |>
  group_by(HANDLER_ID) |>
  summarise(CE_ACTIVITY_STATE = last_known(HANDLER_ACTIVITY_LOCATION),
            CE_LOCATION_STATE = last_known(STATE),
            CE_EPA_REGION     = last_known(REGION),
            CE_LAND_TYPE      = last_known(LAND_TYPE),
            .groups = "drop")

# -- 4. FRS ID and the coordinate slot block ------------------------------------
# Same link as the other panels (see read_frs_links() in 00_panel_functions.R),
# and the same facility-level coordinate block every panel carries (see
# read_hd_coordinates()), which is the one thing this panel takes from the
# Handler master.
frs       <- read_frs_links(ids, frs_file)
hd_coords <- read_hd_coordinates(ids, hd_file)

# -- 5. Balanced grid, assemble, write ------------------------------------------
# expand_grid() emits rows already sorted HANDLER_ID x YEAR x MONTH and the left
# joins preserve that order, so no final arrange over the 3.5M rows is needed.
# Count and indicator columns to zero-fill on months with no action.
count_cols <- c("CE_ENF_TYPE_NUM", "CE_TOTAL_ENF", "CE_TOTAL_STATE_ENF",
                "CE_TOTAL_FED_ENF", "CE_ENF_FORMAL", "CE_ENF_INFORMAL")

out <- expand_grid(HANDLER_ID = ids, YEAR = years, MONTH = 1:12) |>
  # Attach the identifier and the constant handler attributes on ID alone.
  left_join(frs,       by = "HANDLER_ID") |>
  left_join(hd_coords, by = "HANDLER_ID") |>
  left_join(attrs,     by = "HANDLER_ID") |>
  # Attach per-month aggregates; months with no action get NA columns.
  left_join(agg,   by = c("HANDLER_ID", "YEAR", "MONTH")) |>
  # Replace NAs in the count/flag columns with 0, then derive the CE_ANY_* flags.
  mutate(across(all_of(count_cols), \(x) replace_na(x, 0L)),
         CE_ANY_ENF       = as.integer(CE_TOTAL_ENF       > 0),
         CE_ANY_STATE_ENF = as.integer(CE_TOTAL_STATE_ENF > 0),
         CE_ANY_FED_ENF   = as.integer(CE_TOTAL_FED_ENF   > 0)) |>
  # Final panel column order.
  select(HANDLER_ID, FRS_ID, YEAR, MONTH,
         CE_ACTIVITY_STATE, CE_LOCATION_STATE, CE_EPA_REGION, CE_LAND_TYPE,
         all_of(unname(hd_coord_map)),
         CE_ENF_STATE,
         CE_ANY_ENF,       CE_TOTAL_ENF,
         CE_ANY_STATE_ENF, CE_TOTAL_STATE_ENF,
         CE_ANY_FED_ENF,   CE_TOTAL_FED_ENF,
         CE_ENF_TYPE_NUM,  CE_ENF_FORMAL, CE_ENF_INFORMAL,
         CE_ENF_TYPE, CE_ENF_SUBTYPE, CE_ENF_TYPE_DESC, CE_ENF_CATEGORY,
         CE_DOCKET, CE_ENF_SUBORG)

# write_panel() writes the CSV plus an .rds twin: plain CSV stores no column
# types, so read_csv() re-guesses them and mistypes the sparse columns (the
# mostly-empty CE_ENF_CATEGORY reads as a double, which turns every multi-code
# cell into NA, and CE_EPA_REGION "05" loses its leading zero); the .rds copy
# preserves every column's type exactly.
write_panel(out, out_file, rds = TRUE)
