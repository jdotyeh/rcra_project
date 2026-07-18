# =============================================================================
# FILE:     06_wt_exports_master.R
# PURPOSE:  Build the WIETS exports master file by left-joining
#           WT_NOTICES_EXPORTS with its dimension and annual-report tables.
# INPUTS:   data/rcrainfo/wt/*.csv (WT_NOTICES_EXPORTS, WT_AR_<year>, dimensions);
#           sources 00_function.R
# OUTPUTS:  output/modular_master_files/WT_EXPORTS_MASTER.csv
# AUTHOR:   Jason Ye
# CREATED:  2026-07-08
# UPDATED:  2026-07-17
# =============================================================================
#
# Master file for the WIETS (Waste Import Export Tracking System) exports side:
# WT_NOTICES_EXPORTS (one row per export-notice consent / waste stream: the
# consented plan for shipping hazardous waste out of the U.S.) left-joined with
# the annual reports (WT_AR_<year>), which record the ACTUAL quantity and number
# of shipments exported for each consent in a calendar year.
#
# The WT_AR files are keyed by NOTICE_ID + CONSENT_NUMBER (the same key as the
# notice) and are discovered at run time, so new report years are picked up
# automatically. Only the actual-quantity columns are taken from them (the
# exporter / interim / final descriptors they repeat are already on the notice);
# REPORT_YEAR marks which annual report a row's actuals came from. One row per
# export-notice waste stream x annual-report year; a consent with actuals in
# several years expands to one row per year, and a consent never reported keeps
# one row with the annual-report columns blank.
#
# All columns are read as character so zero-padded identifiers, quantities, and
# yyyymmdd date stamps survive verbatim. WIETS carries no Y/N indicator
# columns, so the 1/0 conversion applied in the other masters has nothing to
# convert here.
#
# Requires: tidyverse
# =============================================================================

# Shared master-file helpers: read_module(). Loads tidyverse.
source("code/modules/02_modular_master_files/rcrainfo/00_function.R")

wt_dir   <- "data/rcrainfo/wt"
out_file <- "output/modular_master_files/WT_EXPORTS_MASTER.csv"

read_wt <- function(file) read_module(wt_dir, file)

notices <- read_wt("WT_NOTICES_EXPORTS.csv")

# Stack every annual report on disk, keeping only the consent key and the actual
# quantities; REPORT_YEAR is the four-digit year from the file name.
ar_files <- list.files(wt_dir, pattern = "^WT_AR_\\d{4}\\.csv$")
annual <- map(ar_files, function(f) {
  read_wt(f) |>
    transmute(NOTICE_ID, CONSENT_NUMBER,
              REPORT_YEAR = str_extract(f, "\\d{4}"),
              QUANTITY_ACTUAL, QUANTITY_UOM, SHIPMENTS_ACTUAL)
}) |>
  list_rbind()

master <- notices |>
  left_join(annual, by = c("NOTICE_ID", "CONSENT_NUMBER"),
            relationship = "many-to-many")

master <- master |>
  select(
    # Notice identity
    NOTICE_ID, CONSENT_NUMBER, WASTE_STREAM_NUMBER,
    NOTICE_TYPE, NOTICE_PROGRESS, NOTICE_STATUS,
    # Determination & consent
    DETERMINATION, DETERMINATION_ISSUED_DATE,
    CONSENT_START_DATE, CONSENT_END_DATE, CONSENT_QUANTITY, CONSENT_UOM,
    CONSENT_SHIPMENTS, CONSENT_FREQUENCY, LAST_UPDATED_DATE,
    # Exporter (U.S.)
    EXPORTER_NAME, EXPORTER_EPA_ID, EXPORTER_ADDRESS,
    # Importer (foreign, destination)
    IMPORTER_NAME, IMPORTER_FOREIGN_ID, IMPORTER_ADDRESS, IMPORTER_COUNTRY,
    # Shipper
    SHIPPER_NAME, SHIPPER_EPA_ID, SHIPPER_FOREIGN_ID, SHIPPER_ADDRESS,
    SHIPPER_COUNTRY,
    # Interim receiving facility
    INTERIM_NAME, INTERIM_EPA_ID, INTERIM_FOREIGN_ID, INTERIM_ADDRESS,
    INTERIM_COUNTRY, INTERIM_OPERATIONS,
    # Final recovery / disposal facility
    FINAL_NAME, FINAL_EPA_ID, FINAL_FOREIGN_ID, FINAL_ADDRESS, FINAL_COUNTRY,
    FINAL_OPERATIONS,
    # Waste stream
    WS_WASTE_TYPE, WASTE_DESCRIPTION, HAZARD_CLASS, UN_ID_NUMBER,
    BASEL_WASTE_CODES, EPA_WASTE_CODES,
    # Annual report: actuals exported that year
    REPORT_YEAR, QUANTITY_ACTUAL, QUANTITY_UOM, SHIPMENTS_ACTUAL
  )

write_csv(master, out_file, na = "")
