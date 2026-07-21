# =============================================================================
# FILE:     07_wt_imports_master.R
# PURPOSE:  Build the WIETS imports master file by left-joining
#           WT_NOTICES_IMPORTS with its dimension tables. Mirror of the exports.
# INPUTS:   data/rcrainfo/wt/*.csv (WT_NOTICES_IMPORTS plus its dimension tables);
#           sources 00_function.R
# OUTPUTS:  output/modular_master_files/WT_IMPORTS_MASTER.csv
# AUTHOR:   Jason Ye
# CREATED:  2026-07-08
# UPDATED:  2026-07-17
# =============================================================================
#
# Master file for the WIETS (Waste Import Export Tracking System) imports side:
# WT_NOTICES_IMPORTS (one row per import-notice consent / waste stream: the
# consented plan for bringing hazardous waste into the U.S.). Mirror of the
# exports master, but the U.S. party is the IMPORTER and the foreign / origin
# party is the EXPORTER.
#
# WIETS ships annual-report tables for exports only, so there is nothing to join
# on the imports side: this master is the import-notice table with its columns
# grouped to match WT_EXPORTS_MASTER. One row per import-notice waste stream.
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

# Raw WT module folder and the master output path.
wt_dir   <- "data/rcrainfo/wt"
out_file <- "output/modular_master_files/WT_IMPORTS_MASTER.csv"

# Thin wrapper that fixes the WT folder for read_module().
read_wt <- function(file) read_module(wt_dir, file)

# Import notices, one row per import-notice waste stream; no annual-report
# join because WIETS does not publish annual reports on the imports side.
notices <- read_wt("WT_NOTICES_IMPORTS.csv")

# Reorder columns to match the exports master's grouping.
master <- notices |>
  select(
    # Notice identity
    NOTICE_ID, CONSENT_NUMBER, WASTE_STREAM_NUMBER,
    NOTICE_TYPE, NOTICE_PROGRESS, NOTICE_STATUS,
    # Determination & consent
    DETERMINATION, DETERMINATION_ISSUED_DATE,
    CONSENT_START_DATE, CONSENT_END_DATE, CONSENT_QUANTITY, CONSENT_UOM,
    CONSENT_SHIPMENTS, CONSENT_FREQUENCY, LAST_UPDATED_DATE,
    # Importer (U.S.)
    IMPORTER_NAME, IMPORTER_EPA_ID, IMPORTER_ADDRESS,
    # Exporter (foreign, origin)
    EXPORTER_NAME, EXPORTER_FOREIGN_ID, EXPORTER_ADDRESS, EXPORTER_COUNTRY,
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
    BASEL_WASTE_CODES, EPA_WASTE_CODES
  )

# Write the master with empty-string NAs.
write_csv(master, out_file, na = "")
