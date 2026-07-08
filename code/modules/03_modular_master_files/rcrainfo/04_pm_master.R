# =============================================================================
# 04_pm_master.R
#
# Master file for the Permitting, Closure & Post-Closure (pm) module:
# PM_EVENT (one row per permit/closure event, nested under a permit series)
# crossed with the module's dimensions. One row per event x linked unit-detail x
# waste code x subsequent-modification link; left joins throughout, so an event
# with no linked unit or modification keeps one row with those columns blank.
#
#   PM_SERIES             series the event belongs to (SERIES_NAME + responsible
#                         person, prefixed SERIES_ to avoid colliding with the
#                         event's own responsible-person columns)
#   PM_EVENT_UNIT_DETAIL  event -> unit-detail link (by the event key)
#   PM_UNIT_DETAIL        the process unit's current detail: process code,
#                         capacity, unit of measure, legal/operating status, ...
#   PM_UNIT               process-unit name (UNIT_NAME)
#   PM_UNIT_DETAIL_WASTE  hazardous waste codes handled by the unit detail
#   PM_MOD_EVENT          event (as a modification request) -> the subsequent
#                         modification event it triggered; that follow-on event's
#                         key is carried, prefixed SUBSEQUENT_MOD_ (linkage only)
#
# All columns are read as character so zero-padded identifiers and yyyymmdd date
# stamps survive verbatim.
#
# Requires: tidyverse
# =============================================================================

library(tidyverse)

pm_dir   <- "data/rcrainfo/pm"
out_file <- "output/modular_master_files/PM_MASTER.csv"

read_pm <- function(file) {
  df <- read_csv(file.path(pm_dir, file),
                 col_types = cols(.default = "c"), show_col_types = FALSE)
  names(df) <- gsub(" ", "_", names(df))
  df
}

# Event identity. PM_EVENT spells the handler / series keys HANDLER_ID /
# SERIES_SEQ; the link tables prefix them EVENT_, so the joins map them.
event_tail <- c("EVENT_ACTIVITY_LOCATION", "EVENT_SEQ", "EVENT_AGENCY",
                "EVENT_OWNER", "EVENT_CODE")
# Process-unit-detail identity, shared by the detail, unit, and waste tables.
unit_detail_keys <- c("UNIT_SEQ", "UNIT_DETAIL_SEQ")

event <- read_pm("PM_EVENT.csv")

# Series attributes; prefix its responsible-person columns.
series <- read_pm("PM_SERIES.csv") |>
  rename(SERIES_RESPONSIBLE_PERSON_OWNER = RESPONSIBLE_PERSON_OWNER,
         SERIES_RESPONSIBLE_PERSON       = RESPONSIBLE_PERSON)

event_unit_detail <- read_pm("PM_EVENT_UNIT_DETAIL.csv")
unit_detail       <- read_pm("PM_UNIT_DETAIL.csv")
unit              <- read_pm("PM_UNIT.csv")
unit_detail_waste <- read_pm("PM_UNIT_DETAIL_WASTE.csv")

# PM_MOD_EVENT is a self-link between two PM_EVENT rows: the MOD_ columns are the
# modification-request event, the EVENT_ columns the subsequent modification
# event. Join on the request side; carry the follow-on event's key.
mod_event <- read_pm("PM_MOD_EVENT.csv") |>
  rename(SUBSEQUENT_MOD_HANDLER_ID        = EVENT_HANDLER_ID,
         SUBSEQUENT_MOD_SERIES_SEQ        = EVENT_SERIES_SEQ,
         SUBSEQUENT_MOD_ACTIVITY_LOCATION = EVENT_ACTIVITY_LOCATION,
         SUBSEQUENT_MOD_EVENT_SEQ         = EVENT_SEQ,
         SUBSEQUENT_MOD_EVENT_AGENCY      = EVENT_AGENCY,
         SUBSEQUENT_MOD_EVENT_OWNER       = EVENT_OWNER,
         SUBSEQUENT_MOD_EVENT_CODE        = EVENT_CODE)

master <- event |>
  left_join(series, by = c("HANDLER_ID", "SERIES_SEQ"),
            relationship = "many-to-many") |>
  # event -> process unit(s) it acted on
  left_join(event_unit_detail,
            by = c("HANDLER_ID" = "EVENT_HANDLER_ID",
                   "SERIES_SEQ" = "EVENT_SERIES_SEQ", event_tail),
            relationship = "many-to-many") |>
  left_join(unit_detail,
            by = c("UNIT_DETAIL_HANDLER_ID" = "HANDLER_ID", unit_detail_keys),
            relationship = "many-to-many") |>
  left_join(unit,
            by = c("UNIT_DETAIL_HANDLER_ID" = "HANDLER_ID", "UNIT_SEQ"),
            relationship = "many-to-many") |>
  left_join(unit_detail_waste,
            by = c("UNIT_DETAIL_HANDLER_ID" = "HANDLER_ID", unit_detail_keys),
            relationship = "many-to-many") |>
  # event (as a modification request) -> its subsequent modification event
  left_join(mod_event,
            by = c("HANDLER_ID"             = "MOD_HANDLER_ID",
                   "SERIES_SEQ"             = "MOD_SERIES_SEQ",
                   "EVENT_ACTIVITY_LOCATION" = "MOD_ACTIVITY_LOCATION",
                   "EVENT_SEQ"              = "MOD_EVENT_SEQ",
                   "EVENT_AGENCY"           = "MOD_EVENT_AGENCY",
                   "EVENT_OWNER"            = "MOD_EVENT_OWNER",
                   "EVENT_CODE"             = "MOD_EVENT_CODE"),
            relationship = "many-to-many")

master <- master |>
  select(
    # Event identity
    HANDLER_ID, SERIES_SEQ, EVENT_ACTIVITY_LOCATION, EVENT_SEQ, EVENT_AGENCY,
    EVENT_OWNER, EVENT_CODE,
    # Event information
    ACTUAL_DATE, SCHEDULE_DATE_ORIG, SCHEDULE_DATE_NEW, BEST_DATE,
    RESPONSIBLE_PERSON_OWNER, RESPONSIBLE_PERSON,
    SUBORGANIZATION_OWNER, SUBORGANIZATION,
    # Permit series
    SERIES_NAME, SERIES_RESPONSIBLE_PERSON_OWNER, SERIES_RESPONSIBLE_PERSON,
    # Process-unit-detail linkage
    UNIT_DETAIL_HANDLER_ID, UNIT_SEQ, UNIT_DETAIL_SEQ, UNIT_NAME,
    # Process-unit detail
    EFFECTIVE_DATE, PROCESS_CODE_OWNER, PROCESS_CODE, NUMBER_OF_UNITS,
    CAPACITY, CAPACITY_TYPE, UOM_OWNER, UOM_TYPE,
    LEGAL_OPERATING_STATUS_OWNER, LEGAL_OPERATING_STATUS,
    COMMERCIAL_STATUS, STANDARDIZED_PERMIT_IND, CURRENT_UNIT_DETAIL,
    # Waste code handled by the unit detail
    WASTE_CODE_OWNER, WASTE_CODE,
    # Subsequent modification event (linkage only)
    SUBSEQUENT_MOD_HANDLER_ID, SUBSEQUENT_MOD_SERIES_SEQ,
    SUBSEQUENT_MOD_ACTIVITY_LOCATION, SUBSEQUENT_MOD_EVENT_SEQ,
    SUBSEQUENT_MOD_EVENT_AGENCY, SUBSEQUENT_MOD_EVENT_OWNER,
    SUBSEQUENT_MOD_EVENT_CODE
  )

write_csv(master, out_file, na = "")
