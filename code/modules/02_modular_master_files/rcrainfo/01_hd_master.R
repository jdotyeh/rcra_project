# =============================================================================
# FILE:     01_hd_master.R
# PURPOSE:  Build the Handler module master file by crossing the central
#           HD_HANDLER table with its dimension tables, everything read as
#           character so identifiers and date stamps survive verbatim.
# INPUTS:   data/rcrainfo/hd/*.csv (HD_HANDLER plus its dimension tables),
#           data/frs/FRS_FACILITIES.csv, data/frs/FRS_PROGRAM_LINKS.csv;
#           sources 00_function.R
# OUTPUTS:  output/modular_master_files/HD_MASTER.csv
# AUTHOR:   Jason Ye
# CREATED:  2026-07-08
# UPDATED:  2026-07-21
# =============================================================================
#
# Master file for the Handler (hd) module:
# HD_HANDLER (one row per handler source record) crossed with the module's
# dimension tables. One row per source record x owner x operator x NAICS x
# HSM activity x LQG consolidation x episodic waste x other-ID combination;
# left joins throughout, so records without a match in a dimension keep one
# row with that dimension blank.
#
#   HD_BASIC             REGION, TRIBAL_ID (site level, unique by HANDLER_ID)
#   HD_OWNER_OPERATOR    split by OWNER_OPERATOR_INDICATOR into owners
#                        (CO/PO) and operators (CP/PP), prefixed OWNER_ /
#                        OPERATOR_; ~1.4k rows with a blank indicator are
#                        dropped. DATE_ENDED_CURRENT (dead since V6) dropped.
#   HD_NAICS             NAICS_SEQ, NAICS_CODE
#   HD_HSM_ACTIVITY      HSM_SEQ_NUMBER (linkage only)
#   HD_LQG_CONSOLIDATION CONSOLIDATION_SEQ_NUMBER (linkage only)
#   HD_EPISODIC_WASTE    WASTE_SEQ_NUMBER -> EPISODIC_WASTE_SEQ (linkage only)
#   HD_OTHER_ID          site level: joined by HANDLER_ID + ACTIVITY_LOCATION
#
# Short-term generator notes and per-other-ID public notes are documented in
# the data dictionary but absent from the flat-file extract.
#
# Two recodings are applied on top of the raw values, both documented in the
# module README:
#   - Unknown recodes. Following the ECHO RCRAInfo download summary, an "N" in
#     an activity flag filed before the flag entered the notification form is
#     recoded to "U" (No there is indistinguishable from Unknown); a blank
#     BR_EXEMPT on a pre-2021 report cycle likewise becomes "U".
#   - Indicator conversion. Y/N indicator columns are recoded to 1/0; pure 1/0
#     columns are typed integer, and columns that also carry "U" stay
#     character as "1"/"0"/"U".
#
# On top of the recodings, LOCATION_LATITUDE and LOCATION_LONGITUDE are replaced
# with the coordinates the EPA Facility Registry Service publishes for the same
# facility, on the records where the two sources can be shown to describe the
# same place. A record qualifies when its normalised address matches the FRS
# address, or when its handler holds only a few coordinate pairs, one of which
# is the FRS pair with the rest within a kilometre of it. Everything else keeps
# the coordinates the facility reported, because a registry identifier follows a
# facility that may have moved. LOCATION_COORD_SOURCE records which rule, if
# any, supplied the pair on the record, holding "HD", "FRS_ADDRESS", or
# "FRS_COORDINATE". The rules and their thresholds are documented above
# apply_frs_coordinates() in 00_function.R.
#
# All columns are read as character so zero-padded identifiers and yyyymmdd
# date stamps survive verbatim. Inputs are large (HD_HANDLER alone is 2.2 GB),
# so columns are trimmed right after each read and inputs are released with
# rm()/gc() as soon as they are joined.
#
# Requires: tidyverse
# =============================================================================

# Shared master-file helpers: read_module(), the two unknown-recode helpers,
# convert_indicators(), and apply_frs_coordinates(). Loads tidyverse.
source("code/modules/02_modular_master_files/rcrainfo/00_function.R")

# Raw HD module folder and the final master output path.
hd_dir   <- "data/rcrainfo/hd"
out_file <- "output/modular_master_files/HD_MASTER.csv"

# Thin wrapper around read_module() that fixes the HD folder.
read_hd <- function(file) read_module(hd_dir, file)

# Source-record identity shared by every source-level table.
rec_keys <- c("HANDLER_ID", "ACTIVITY_LOCATION", "SOURCE_TYPE", "SEQ_NUMBER")

# MANIFEST_BROKER (the eManifest broker flag) is kept: it is one of the flags
# the download summary's unknown rules speak about.
# Drop columns that are always empty or duplicated by other tables (LAND_TYPE
# comes from CE_REPORTING, LOCATION_COUNTRY is always US, GIS columns are
# unpopulated, CONTACT_LANGUAGE is not used).
handler <- read_hd("HD_HANDLER.csv") |>
  select(-LAND_TYPE, -LOCATION_COUNTRY, -LOCATION_GIS_PRIMARY,
         -LOCATION_GIS_ORIGIN, -CONTACT_LANGUAGE)

# ---- Unknown recodes (ECHO RCRAInfo download summary) -----------------------
# For each flag below, an "N" recorded before the flag entered the notification
# form does not distinguish No from Unknown, so those entries become an
# explicit "U". Counts are from the 2026-07-05 EPA export (4,224,944
# HD_HANDLER records).

# Rule 1: flags unavailable on source documents I, R, E, T before 4/1/2010
# (~717k-762k entries per flag recoded).
pre2010_iret <- c(
  "SHORT_TERM_GENERATOR", "IMPORTER_ACTIVITY", "MIXED_WASTE_GENERATOR",
  "TRANSPORTER", "TSD_ACTIVITY", "RECYCLER_ACTIVITY",
  "ONSITE_BURNER_EXEMPTION", "FURNACE_EXEMPTION",
  "UNDERGROUND_INJECTION_ACTIVITY", "UNIVERSAL_WASTE_DEST_FACILITY",
  "USED_OIL_TRANSPORTER", "USED_OIL_TRANSFER_FACILITY", "USED_OIL_PROCESSOR",
  "USED_OIL_REFINER", "USED_OIL_BURNER", "USED_OIL_MARKET_BURNER",
  "USED_OIL_SPEC_MARKETER")
# Rule 4: Subpart H recognized traders + Subpart G SLAB importers/exporters,
# before 12/20/2016 (~2.59M entries each).
pre2016_trade <- c("RECOGNIZED_TRADER_IMPORTER", "RECOGNIZED_TRADER_EXPORTER",
                   "SLAB_IMPORTER", "SLAB_EXPORTER")
# Rule 5: no-storage recyclers + eManifest brokers, before 6/1/2017 (~31k each).
pre2017_flags <- c("RECYCLER_ACTIVITY_NONSTORAGE", "MANIFEST_BROKER")
# Rule 6: Subpart P healthcare facilities + reverse distributors, before
# 8/21/2019 (~2.96M each).
pre2019_subp <- c("SUBPART_P_HEALTHCARE", "SUBPART_P_REVERSE_DISTRIBUTOR")

handler <- handler |>
  # Rule 1: I/R/E/T records only, "N" -> "U" before the 2010 cutoff.
  recode_pre_date_unknown(pre2010_iret, 20100401L, c("I", "R", "E", "T")) |>
  # Rule 2: transfer-facility activity, every source type, before 4/1/2010
  # (1,965,791 entries recoded).
  recode_pre_date_unknown("TRANSFER_FACILITY", 20100401L) |>
  # Rule 3: a blank BR_EXEMPT on a report cycle before 2021 is unknown, not a
  # non-exemption (394,241 entries recoded; records with no cycle stay blank).
  recode_pre_cycle_unknown("BR_EXEMPT", 2021L) |>
  # Rule 4: recognized-trader / SLAB flags before 12/20/2016 (~2.59M each).
  recode_pre_date_unknown(pre2016_trade, 20161220L) |>
  # Rule 5: no-storage recyclers + eManifest brokers, before 6/1/2017.
  recode_pre_date_unknown(pre2017_flags, 20170601L) |>
  # Rule 6: Subpart P flags before 8/21/2019 (~2.96M each).
  recode_pre_date_unknown(pre2019_subp, 20190821L)

# ---- Indicator conversion (Y/N -> 1/0, "U" preserved) -----------------------
# Every Y/N indicator on the handler record. ACKNOWLEDGE_FLAG is deliberately
# absent: its raw values are a mix of dozens of codes, not a Y/N flag.
# INCLUDE_IN_NATIONAL_REPORT ships with its own "U" (pre-2001 records), and the
# recoded flags above now carry "U" too, so those columns stay character as
# "1"/"0"/"U"; the rest become integer 1/0.
handler <- convert_indicators(handler, c(
  "CURRENT_RECORD", "INCLUDE_IN_NATIONAL_REPORT", "BR_EXEMPT",
  "SUBPART_K_COLLEGE", "SUBPART_K_HOSPITAL", "SUBPART_K_NONPROFIT",
  "SUBPART_K_WITHDRAWAL", "SUBPART_P_WITHDRAWAL",
  "OFF_SITE_RECEIPT", "LQHUW",
  pre2010_iret, "TRANSFER_FACILITY", pre2016_trade, pre2017_flags,
  pre2019_subp))

# ---- FRS coordinates --------------------------------------------------------
# Bring in the Facility Registry Service coordinates on the records where the
# address or the handler's own coordinates show the two sources describe the
# same place, and stamp LOCATION_COORD_SOURCE with the rule that supplied each
# record's pair. This runs before the dimension joins, while the table is still
# one row per source record, so the address normalisation and the two joins
# never see the fanout the joins below introduce.
handler <- apply_frs_coordinates(handler)

# Site-level basics: REGION and TRIBAL_ID join on HANDLER_ID only.
basic <- read_hd("HD_BASIC.csv") |>
  select(HANDLER_ID, REGION, TRIBAL_ID)

# One owner table and one operator table so each contributes its own column
# block; a record with several owners and operators legitimately expands.
# DATE_ENDED_CURRENT has been dead since V6 and is dropped up front.
owner_operator <- read_hd("HD_OWNER_OPERATOR.csv") |>
  select(-DATE_ENDED_CURRENT)

# Owners are the CO/PO rows; strip the OWNER_OPERATOR_ prefix and re-prefix
# with OWNER_ so the master keeps an owner-specific column block.
owner <- owner_operator |>
  filter(OWNER_OPERATOR_INDICATOR %in% c("CO", "PO")) |>
  rename_with(\(x) str_remove(x, "^OWNER_OPERATOR_"), -all_of(rec_keys)) |>
  rename_with(\(x) paste0("OWNER_", x), -all_of(rec_keys))

# Operators are the CP/PP rows; same rename pattern with the OPERATOR_ prefix.
operator <- owner_operator |>
  filter(OWNER_OPERATOR_INDICATOR %in% c("CP", "PP")) |>
  rename_with(\(x) str_remove(x, "^OWNER_OPERATOR_"), -all_of(rec_keys)) |>
  rename_with(\(x) paste0("OPERATOR_", x), -all_of(rec_keys))

# Release the combined table once the two prefixed copies exist.
rm(owner_operator); invisible(gc())

# Industry classification, keyed on the source record.
naics <- read_hd("HD_NAICS.csv") |>
  select(all_of(rec_keys), NAICS_SEQ, NAICS_CODE)

# HSM activity linkage; only the sequence number is carried through.
hsm <- read_hd("HD_HSM_ACTIVITY.csv") |>
  select(all_of(rec_keys), HSM_SEQ_NUMBER)

# LQG consolidation linkage; only the sequence number is carried through.
consolidation <- read_hd("HD_LQG_CONSOLIDATION.csv") |>
  select(all_of(rec_keys), CONSOLIDATION_SEQ_NUMBER)

# Episodic waste linkage; rename WASTE_SEQ_NUMBER to disambiguate.
episodic_waste <- read_hd("HD_EPISODIC_WASTE.csv") |>
  select(all_of(rec_keys), EPISODIC_WASTE_SEQ = WASTE_SEQ_NUMBER)

# SAME_FACILITY ships as Y/N/U, so it stays character as "1"/"0"/"U".
other_id <- read_hd("HD_OTHER_ID.csv") |>
  convert_indicators("SAME_FACILITY")

# Join dimension tables one at a time and free each after use; HD_HANDLER is
# 2.2 GB alone, so holding every intermediate would blow the memory budget.
master <- handler |>
  left_join(basic, by = "HANDLER_ID")
rm(handler, basic); invisible(gc())

# Owner block; many-to-many because a record can have multiple owners.
master <- master |>
  left_join(owner, by = rec_keys, relationship = "many-to-many")
rm(owner); invisible(gc())

# Operator block; same relationship rationale as owners.
master <- master |>
  left_join(operator, by = rec_keys, relationship = "many-to-many")
rm(operator); invisible(gc())

# NAICS block; multiple codes per record are common, so many-to-many.
master <- master |>
  left_join(naics, by = rec_keys, relationship = "many-to-many")
rm(naics); invisible(gc())

# Remaining linkages joined together, then released.
master <- master |>
  left_join(hsm, by = rec_keys, relationship = "many-to-many") |>
  left_join(consolidation, by = rec_keys, relationship = "many-to-many") |>
  left_join(episodic_waste, by = rec_keys, relationship = "many-to-many") |>
  # HD_OTHER_ID is site-level, so it joins on HANDLER_ID + ACTIVITY_LOCATION only.
  left_join(other_id, by = c("HANDLER_ID", "ACTIVITY_LOCATION"),
            relationship = "many-to-many")
rm(hsm, consolidation, episodic_waste, other_id); invisible(gc())

master <- master |>
  select(
    # Basic information: big four + current record
    HANDLER_ID, ACTIVITY_LOCATION, SOURCE_TYPE, SEQ_NUMBER, CURRENT_RECORD,
    # Linkage sequence numbers
    OWNER_SEQ, OPERATOR_SEQ, NAICS_SEQ, HSM_SEQ_NUMBER,
    CONSOLIDATION_SEQ_NUMBER, EPISODIC_WASTE_SEQ,
    # EPA bookkeeping
    HANDLER_NAME, RECEIVE_DATE, ACKNOWLEDGE_FLAG, ACKNOWLEDGE_DATE,
    # Geographics & demographics
    ACCESSIBILITY,
    LOCATION_STREET_NO, LOCATION_STREET1, LOCATION_STREET2, LOCATION_CITY,
    COUNTY_CODE, LOCATION_STATE, TRIBAL_ID, REGION, LOCATION_ZIP,
    LOCATION_LATITUDE, LOCATION_LONGITUDE, LOCATION_COORD_SOURCE,
    STATE_DISTRICT_OWNER, STATE_DISTRICT,
    # Contact information: mailing address
    MAIL_STREET_NO, MAIL_STREET1, MAIL_STREET2, MAIL_CITY, MAIL_STATE,
    MAIL_ZIP, MAIL_COUNTRY,
    # Contact information: contact person
    CONTACT_FIRST_NAME, CONTACT_MIDDLE_INITIAL, CONTACT_LAST_NAME,
    CONTACT_TITLE, CONTACT_EMAIL_ADDRESS,
    # Contact information: contact address
    CONTACT_STREET_NO, CONTACT_STREET1, CONTACT_STREET2, CONTACT_CITY,
    CONTACT_STATE, CONTACT_ZIP, CONTACT_COUNTRY, CONTACT_PHONE,
    CONTACT_PHONE_EXT, CONTACT_FAX,
    # Owner information
    OWNER_INDICATOR, OWNER_NAME, OWNER_TYPE, OWNER_DATE_BECAME_CURRENT,
    OWNER_STREET_NO, OWNER_STREET1, OWNER_STREET2, OWNER_CITY, OWNER_STATE,
    OWNER_ZIP, OWNER_COUNTRY, OWNER_PHONE, OWNER_PHONE_EXT, OWNER_FAX,
    OWNER_EMAIL,
    # Operator information
    OPERATOR_INDICATOR, OPERATOR_NAME, OPERATOR_TYPE,
    OPERATOR_DATE_BECAME_CURRENT,
    OPERATOR_STREET_NO, OPERATOR_STREET1, OPERATOR_STREET2, OPERATOR_CITY,
    OPERATOR_STATE, OPERATOR_ZIP, OPERATOR_COUNTRY, OPERATOR_PHONE,
    OPERATOR_PHONE_EXT, OPERATOR_FAX, OPERATOR_EMAIL,
    # Facility general information: NAICS + RCRA-regulated status
    NAICS_CODE,
    NON_NOTIFIER, INCLUDE_IN_NATIONAL_REPORT, REPORT_CYCLE, BR_EXEMPT,
    # Generator
    FED_WASTE_GENERATOR_OWNER, FED_WASTE_GENERATOR,
    STATE_WASTE_GENERATOR_OWNER, STATE_WASTE_GENERATOR,
    SHORT_TERM_GENERATOR, MIXED_WASTE_GENERATOR, IMPORTER_ACTIVITY,
    SUBPART_K_COLLEGE, SUBPART_K_HOSPITAL, SUBPART_K_NONPROFIT,
    SUBPART_K_WITHDRAWAL,
    SUBPART_P_HEALTHCARE, SUBPART_P_REVERSE_DISTRIBUTOR, SUBPART_P_WITHDRAWAL,
    RECOGNIZED_TRADER_IMPORTER, RECOGNIZED_TRADER_EXPORTER,
    SLAB_IMPORTER, SLAB_EXPORTER,
    # Transporter
    TRANSPORTER, TRANSFER_FACILITY,
    # TSDF
    TSD_ACTIVITY, RECYCLER_ACTIVITY, RECYCLER_ACTIVITY_NONSTORAGE,
    ONSITE_BURNER_EXEMPTION, FURNACE_EXEMPTION,
    UNDERGROUND_INJECTION_ACTIVITY, OFF_SITE_RECEIPT, LQHUW,
    UNIVERSAL_WASTE_DEST_FACILITY,
    # eManifest
    MANIFEST_BROKER,
    # Used oil
    USED_OIL_TRANSPORTER, USED_OIL_TRANSFER_FACILITY, USED_OIL_PROCESSOR,
    USED_OIL_REFINER, USED_OIL_BURNER, USED_OIL_MARKET_BURNER,
    USED_OIL_SPEC_MARKETER,
    # Other ID
    OTHER_ID, SAME_FACILITY, RELATIONSHIP_OWNER, RELATIONSHIP,
    # Misc.
    PUBLIC_NOTES, OWNER_PUBLIC_NOTES, OPERATOR_PUBLIC_NOTES
  )

# Write the master with empty-string NAs so downstream readers do not carry
# stray "NA" tokens.
write_csv(master, out_file, na = "")
