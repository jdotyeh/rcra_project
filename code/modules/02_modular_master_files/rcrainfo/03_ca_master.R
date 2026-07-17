# =============================================================================
# FILE:     03_ca_master.R
# PURPOSE:  Build the Corrective Action module master file by crossing CA_EVENT
#           with the module's linked dimension tables.
# INPUTS:   data/rcrainfo/ca/*.csv (CA_EVENT plus its dimension tables)
# OUTPUTS:  output/modular_master_files/CA_MASTER.csv
# AUTHOR:   Jason Ye
# CREATED:  2026-07-08
# UPDATED:  2026-07-08
# =============================================================================
#
# Master file for the Corrective Action (ca) module:
# CA_EVENT (one row per corrective-action event/milestone at a handler) crossed
# with the module's linked dimensions. One row per event x linked area x area
# process-unit x linked authority x statutory citation; left joins throughout,
# so an event with no area or authority link keeps one row with those columns
# blank.
#
#   CA_AREA_EVENT   event -> area link (by the event key)
#   CA_AREA         area attributes: release indicators (air/groundwater/soil/
#                   surface water), acreage, name, EPA/state responsible person
#   CA_AREA_UNIT    area -> process-unit link (UNIT_HANDLER_ID, UNIT_SEQ;
#                   linkage only, ties an area to a PM/HD process unit)
#   CA_EVENT_AUTHORITY  event -> authority link (by the event key)
#   CA_AUTHORITY    authority attributes (dates, repository, responsible person,
#                   suborganization), prefixed AUTHORITY_ so they never collide
#                   with the event's own responsible-person / suborg columns
#   CA_AUTHORITY_CITATION  statutory citation carried by the authority
#
# The area and the authority are independent dimensions of an event, so an event
# linked to several of each expands to their product (as in HD_MASTER).
#
# All columns are read as character so zero-padded identifiers and yyyymmdd date
# stamps survive verbatim.
#
# Requires: tidyverse
# =============================================================================

library(tidyverse)

ca_dir   <- "data/rcrainfo/ca"
out_file <- "output/modular_master_files/CA_MASTER.csv"

read_ca <- function(file) {
  df <- read_csv(file.path(ca_dir, file),
                 col_types = cols(.default = "c"), show_col_types = FALSE)
  names(df) <- gsub(" ", "_", names(df))
  df
}

# Event identity. In CA_EVENT the handler column is HANDLER_ID; the link tables
# spell the same key EVENT_HANDLER_ID, so the joins map it explicitly.
event_keys <- c("EVENT_ACTIVITY_LOCATION", "EVENT_SEQ", "EVENT_AGENCY",
                "EVENT_OWNER", "EVENT_CODE")
# Authority identity, shared by the authority table and its citation child.
authority_keys <- c("AUTHORITY_ACTIVITY_LOCATION", "AUTHORITY_AGENCY",
                    "AUTHORITY_OWNER", "AUTHORITY_TYPE", "AUTHORITY_EFFECTIVE_DATE")

event <- read_ca("CA_EVENT.csv")

area_event <- read_ca("CA_AREA_EVENT.csv")
area       <- read_ca("CA_AREA.csv")
area_unit  <- read_ca("CA_AREA_UNIT.csv")

event_authority <- read_ca("CA_EVENT_AUTHORITY.csv")

# Prefix the authority's own attribute columns so they do not clash with the
# event's RESPONSIBLE_PERSON_* / SUBORGANIZATION_* columns.
authority <- read_ca("CA_AUTHORITY.csv") |>
  rename(AUTHORITY_ISSUE_DATE               = ISSUE_DATE,
         AUTHORITY_END_DATE                 = END_DATE,
         AUTHORITY_REPOSITORY               = REPOSITORY,
         AUTHORITY_RESPONSIBLE_PERSON_OWNER = RESPONSIBLE_PERSON_OWNER,
         AUTHORITY_RESPONSIBLE_PERSON       = RESPONSIBLE_PERSON,
         AUTHORITY_SUBORGANIZATION_OWNER    = SUBORGANIZATION_OWNER,
         AUTHORITY_SUBORGANIZATION          = SUBORGANIZATION)

authority_citation <- read_ca("CA_AUTHORITY_CITATION.csv")

master <- event |>
  # event -> its corrective-action area(s)
  left_join(area_event, by = c("HANDLER_ID" = "EVENT_HANDLER_ID", event_keys),
            relationship = "many-to-many") |>
  left_join(area, by = c("AREA_HANDLER_ID" = "HANDLER_ID", "AREA_SEQ"),
            relationship = "many-to-many") |>
  left_join(area_unit, by = c("AREA_HANDLER_ID", "AREA_SEQ"),
            relationship = "many-to-many") |>
  # event -> the authority(ies) that ordered it, then each authority's citation
  left_join(event_authority, by = c("HANDLER_ID" = "EVENT_HANDLER_ID", event_keys),
            relationship = "many-to-many") |>
  left_join(authority,
            by = c("AUTHORITY_HANDLER_ID" = "HANDLER_ID", authority_keys),
            relationship = "many-to-many") |>
  left_join(authority_citation,
            by = c("AUTHORITY_HANDLER_ID" = "HANDLER_ID", authority_keys),
            relationship = "many-to-many")

master <- master |>
  select(
    # Event identity
    HANDLER_ID, EVENT_ACTIVITY_LOCATION, EVENT_SEQ, EVENT_AGENCY, EVENT_OWNER,
    EVENT_CODE,
    # Event information
    SCHEDULE_DATE_ORIG, SCHEDULE_DATE_NEW, ACTUAL_DATE, BEST_DATE,
    RESPONSIBLE_PERSON_OWNER, RESPONSIBLE_PERSON,
    SUBORGANIZATION_OWNER, SUBORGANIZATION, PUBLIC_NOTES,
    # Corrective-action area: linkage + attributes
    AREA_HANDLER_ID, AREA_SEQ, AREA_NAME,
    ENTIRE_FACILITY_IND, REGULATED_UNIT_IND,
    AIR_RELEASE_IND, GROUNDWATER_RELEASE_IND, SOIL_RELEASE_IND,
    SURFACE_WATER_RELEASE_IND,
    EPA_OWNER, EPA_PERSON_ID, STATE_OWNER, STATE_PERSON_ID, AREA_ACREAGE,
    # Area -> process-unit linkage
    UNIT_HANDLER_ID, UNIT_SEQ,
    # Authority: linkage + attributes
    AUTHORITY_HANDLER_ID, AUTHORITY_ACTIVITY_LOCATION, AUTHORITY_AGENCY,
    AUTHORITY_OWNER, AUTHORITY_TYPE, AUTHORITY_EFFECTIVE_DATE,
    AUTHORITY_ISSUE_DATE, AUTHORITY_END_DATE, AUTHORITY_REPOSITORY,
    AUTHORITY_RESPONSIBLE_PERSON_OWNER, AUTHORITY_RESPONSIBLE_PERSON,
    AUTHORITY_SUBORGANIZATION_OWNER, AUTHORITY_SUBORGANIZATION,
    # Statutory citation
    STATUTORY_OWNER, STATUTORY_CITATION
  )

write_csv(master, out_file, na = "")
