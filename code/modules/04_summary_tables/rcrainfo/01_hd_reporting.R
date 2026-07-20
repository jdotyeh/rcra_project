# =============================================================================
# FILE:     01_hd_reporting.R
# PURPOSE:  Build the Handler module summary workbook from the HD_MASTER master
#           file, using the shared engine.
# INPUTS:   output/modular_master_files/HD_MASTER.csv; sources 00_function.R
# OUTPUTS:  output/summary_tables/Handler Module Summary Tables.xlsx
# AUTHOR:   Jason Ye
# CREATED:  2026-07-07
# UPDATED:  2026-07-19
# =============================================================================

# "Handler Module Summary Tables.xlsx" from HD_MASTER, the Handler module's
# analysis-ready master file, via the shared engine (00_function.R). Defines
# the spec (which columns are Categorical / Quantitative / Dummy + value
# labels) and calls build_module_summary().
#
# The spec covers every column of the master that carries a coded, dated,
# numeric, or indicator value. What is left out is the site name, the four
# correspondence-address blocks (mailing, contact, owner, operator), the
# contact and owner phone, fax, and email columns, the alternate identifier,
# and the three public-note fields. The site's own geography stays in, because
# the region, state, county, ZIP, tribal land, state district, and coordinates
# are what place a record on the map.
#
# The master codes its indicators 1/0, with "U" (unknown) where an "N"
# predates the flag's existence (recode rules in the 02_modular_master_files
# README); the engine's Dummy tab counts the three codes separately.
#
# Reads output/modular_master_files/HD_MASTER.csv; writes
# output/summary_tables/Handler Module Summary Tables.xlsx.
# Requires: tidyverse, lubridate, openxlsx2. Run from the repo root.

source("code/modules/04_summary_tables/rcrainfo/00_function.R")

hd_file  <- "output/modular_master_files/HD_MASTER.csv"
out_file <- "output/summary_tables/Handler Module Summary Tables.xlsx"

# ---- Value-label dictionaries (embedded; only the master file is needed) -----
# Only the codes that reach a variable's five most frequent values need a label,
# so each dictionary stays short and the workbook needs no lookup file.
lab_source <- c(I = "Implementer", N = "Notification",
                B = "Annual/Biennial Report\nUpdate with Notification",
                D = "Deactivation", `T` = "Temporary")
lab_fedgen <- c(`1` = "Large Quantity Generator", `2` = "Small Quantity Generator",
                `3` = "Very Small Quantity Generator", N = "Not a Generator",
                U = "Unknown")
# Owner and operator types share the land-ownership code list.
lab_owner  <- c(P = "Private", C = "County", D = "District", F = "Federal",
                I = "Indian/Tribal", M = "Municipal", S = "State", O = "Other")
lab_ownind <- c(CO = "Current Owner", PO = "Previous Owner")
lab_opind  <- c(CP = "Current Operator", PP = "Previous Operator")
lab_county <- c(CA037 = "Los Angeles", WA033 = "King", CA059 = "Orange",
                CA073 = "San Diego", NY061 = "New York")
lab_naics  <- c(`56299`  = "All Other Waste Management Services",
                `811111` = "General Automotive Repair",
                `811121` = "Automotive Body, Paint, and Interior Repair and Maintenance",
                `44611`  = "Pharmacies and Drug Stores",
                `56291`  = "Remediation Services",
                `44711`  = "Gasoline Stations with Convenience Stores")
# Alternate-identifier relationships, shortened from HD_LU_RELATIONSHIP.
lab_relate <- c(C = "Converted Second ID", S = "State-Issued ID, May Still Be Used",
                P = "Former ID, No Longer Used", O = "Other ID Used At Site",
                M = "One Of Multiple Occupants", N = "Additional ID Issued To Site",
                F = "ID Of Fragment That Split Off")

# ---- Spec -------------------------------------------------------------------
id_col <- "HANDLER_ID"
cat_spec <- list(
  list(col = "ACTIVITY_LOCATION", name = "ACTIVITY_LOCATION", labels = NULL,
       desc = "The state or territory whose implementing agency is responsible for the site."),
  list(col = "SOURCE_TYPE", name = "SOURCE_TYPE", labels = lab_source,
       desc = "Type of source document providing the record."),
  list(col = "ACKNOWLEDGE_FLAG", name = "ACKNOWLEDGE_FLAG", labels = NULL,
       desc = "Flag marking the site for an acknowledgement of receipt."),
  list(col = "ACCESSIBILITY", name = "ACCESSIBILITY", labels = NULL,
       desc = "Reason the site is not accessible for normal RCRA tracking and processing."),
  list(col = "REGION", name = "REGION", labels = NULL,
       desc = "EPA region in which the site is located."),
  list(col = "LOCATION_STATE", name = "LOCATION_STATE", labels = NULL,
       desc = "State in which the site is physically located."),
  list(col = "COUNTY_CODE", name = "COUNTY_CODE", labels = lab_county,
       desc = "County in which the site is physically located."),
  list(col = "LOCATION_ZIP", name = "LOCATION_ZIP", labels = NULL,
       desc = "ZIP code of the site's physical location."),
  list(col = "TRIBAL_ID", name = "TRIBAL_ID", labels = NULL,
       desc = "Tribe on whose land the site is located."),
  list(col = "STATE_DISTRICT_OWNER", name = "STATE_DISTRICT_OWNER", labels = NULL,
       desc = "State that defines the district code carried on the record."),
  list(col = "STATE_DISTRICT", name = "STATE_DISTRICT", labels = NULL,
       desc = "Administrative district the state assigns the site to (codes are state-specific)."),
  list(col = "OWNER_INDICATOR", name = "OWNER_INDICATOR", labels = lab_ownind,
       desc = "Whether the owner row describes a current or a previous owner."),
  list(col = "OWNER_TYPE", name = "OWNER_TYPE", labels = lab_owner,
       desc = "Ownership type of the site's owner."),
  list(col = "OPERATOR_INDICATOR", name = "OPERATOR_INDICATOR", labels = lab_opind,
       desc = "Whether the operator row describes a current or a previous operator."),
  list(col = "OPERATOR_TYPE", name = "OPERATOR_TYPE", labels = lab_owner,
       desc = "Ownership type of the site's operator."),
  list(col = "NAICS_CODE", name = "NAICS_CODE", labels = lab_naics,
       desc = "NAICS industry classification listed for the site (one row per listed code)."),
  list(col = "NON_NOTIFIER", name = "NON_NOTIFIER", labels = NULL,
       desc = "Marks a site found through a source other than notification and suspected of regulated activity without authority."),
  list(col = "FED_WASTE_GENERATOR_OWNER", name = "FED_WASTE_GENERATOR_OWNER", labels = NULL,
       desc = "Organization that defines the federal generator-status code list."),
  list(col = "FED_WASTE_GENERATOR", name = "FED_WASTE_GENERATOR", labels = lab_fedgen,
       desc = "Generator status of the site according to Federal regulations."),
  list(col = "STATE_WASTE_GENERATOR_OWNER", name = "STATE_WASTE_GENERATOR_OWNER", labels = NULL,
       desc = "State that defines the state generator-status code list."),
  list(col = "STATE_WASTE_GENERATOR", name = "STATE_WASTE_GENERATOR", labels = NULL,
       desc = "Generator status of the site according to the implementing state's regulations."),
  list(col = "RELATIONSHIP_OWNER", name = "RELATIONSHIP_OWNER", labels = NULL,
       desc = "Organization that defines the alternate-identifier relationship code list."),
  list(col = "RELATIONSHIP", name = "RELATIONSHIP", labels = lab_relate,
       desc = "How an alternate identifier on file relates to this site.")
)
quant_dates <- c("RECEIVE_DATE", "ACKNOWLEDGE_DATE",
                 "OWNER_DATE_BECAME_CURRENT", "OPERATOR_DATE_BECAME_CURRENT")
quant_nums  <- c(SEQ_NUMBER = 0L, OWNER_SEQ = 0L, OPERATOR_SEQ = 0L, NAICS_SEQ = 0L,
                 HSM_SEQ_NUMBER = 0L, CONSOLIDATION_SEQ_NUMBER = 0L,
                 EPISODIC_WASTE_SEQ = 0L, REPORT_CYCLE = 0L,
                 LOCATION_LATITUDE = 2L, LOCATION_LONGITUDE = 2L)
# Every 1/0(/U) indicator on the master, in the master's column order.
flag_simple <- c(
  "CURRENT_RECORD", "INCLUDE_IN_NATIONAL_REPORT", "BR_EXEMPT",
  "SHORT_TERM_GENERATOR", "MIXED_WASTE_GENERATOR", "IMPORTER_ACTIVITY",
  "SUBPART_K_COLLEGE", "SUBPART_K_HOSPITAL", "SUBPART_K_NONPROFIT",
  "SUBPART_K_WITHDRAWAL",
  "SUBPART_P_HEALTHCARE", "SUBPART_P_REVERSE_DISTRIBUTOR", "SUBPART_P_WITHDRAWAL",
  "RECOGNIZED_TRADER_IMPORTER", "RECOGNIZED_TRADER_EXPORTER",
  "SLAB_IMPORTER", "SLAB_EXPORTER",
  "TRANSPORTER", "TRANSFER_FACILITY",
  "TSD_ACTIVITY", "RECYCLER_ACTIVITY", "RECYCLER_ACTIVITY_NONSTORAGE",
  "ONSITE_BURNER_EXEMPTION", "FURNACE_EXEMPTION",
  "UNDERGROUND_INJECTION_ACTIVITY", "OFF_SITE_RECEIPT", "LQHUW",
  "UNIVERSAL_WASTE_DEST_FACILITY", "MANIFEST_BROKER",
  "USED_OIL_TRANSPORTER", "USED_OIL_TRANSFER_FACILITY", "USED_OIL_PROCESSOR",
  "USED_OIL_REFINER", "USED_OIL_BURNER", "USED_OIL_MARKET_BURNER",
  "USED_OIL_SPEC_MARKETER", "SAME_FACILITY")

# ---- Load (only the needed columns; the master ships underscore names) -------
# HD_MASTER is the largest file in the project, so the read is still restricted
# to the spec columns even though the spec now covers most of the file.
need <- needed_columns(cat_spec, quant_dates, quant_nums, flag_simple, id_col = id_col)
all_cols <- read_csv(hd_file, n_max = 0, show_col_types = FALSE) |> names()
hd <- read_csv(hd_file, col_select = all_of(need),
               col_types = cols(.default = col_character()))

build_module_summary(
  data = hd, all_cols = all_cols, out_file = out_file, id_col = id_col,
  temporal_col = "RECEIVE_DATE",
  banner = "Identifier: HANDLER_ID, one row per handler source record x owner x operator x NAICS x HSM x consolidation x episodic waste x other-ID combination.",
  cat_spec = cat_spec, quant_dates = quant_dates, quant_nums = quant_nums,
  flag_simple = flag_simple,
  module_desc = "Handlers - generators + transporters + TSDFs (treatment, storage, or disposal facilities). Summarized from the HD_MASTER master file.",
  missing_notes = list(
    categorical = c(
      "ACKNOWLEDGE_FLAG / ACCESSIBILITY: Not applicable. Both are set only on the handful of records that need an acknowledgement or are flagged as inaccessible.",
      "TRIBAL_ID: Not applicable. Only sites on tribal land carry one.",
      "STATE_DISTRICT_OWNER / STATE_DISTRICT: Not applicable. Only the states that run district programs assign one.",
      "OWNER_INDICATOR / OWNER_TYPE / OPERATOR_INDICATOR / OPERATOR_TYPE: Missing. Records with no owner or operator row of that kind.",
      "NAICS_CODE: Missing. Incomplete reporting.",
      "NON_NOTIFIER: Not applicable. Set only on the sites EPA reached outside the notification process.",
      "RELATIONSHIP_OWNER / RELATIONSHIP: Not applicable. Set only on records that carry an alternate identifier.",
      "Note: EPA Regions
EPA Region 1: Connecticut, Maine, Massachusetts, New Hampshire, Rhode Island, Vermont
EPA Region 2: New Jersey, New York, Puerto Rico, Virgin Islands
EPA Region 3: Delaware, District of Columbia, Maryland, Pennsylvania, Virginia, West Virginia
EPA Region 4: Alabama, Florida, Georgia, Kentucky, Mississippi, North Carolina, South Carolina, Tennessee
EPA Region 5: Illinois, Indiana, Michigan, Minnesota, Ohio, Wisconsin
EPA Region 6: Arkansas, Louisiana, New Mexico, Oklahoma, Texas
EPA Region 7: Iowa, Kansas, Missouri, Nebraska
EPA Region 8: Colorado, Montana, North Dakota, South Dakota, Utah, Wyoming
EPA Region 9: American Samoa, Arizona, California, Guam, Hawaii, Navajo Nations, Northern Marianas, Nevada, Trust Territories
EPA Region 10: Alaska, Idaho, Oregon, Washington"
    ),
    quantitative = c(
      "ACKNOWLEDGE_DATE: Not applicable. Only acknowledged records carry one, and the minimum reflects placeholder dates EPA ships rather than real receipts.",
      "OWNER_DATE_BECAME_CURRENT / OPERATOR_DATE_BECAME_CURRENT: Missing. Blank on records with no owner or operator row, and on owner rows that never reported the date.",
      "LOCATION_LATITUDE/LOCATION_LONGITUDE: Missing. Not reported.",
      "REPORT_CYCLE: Not applicable. Only Biennial-Report-fed records carry a cycle.",
      "HSM_SEQ_NUMBER / CONSOLIDATION_SEQ_NUMBER / EPISODIC_WASTE_SEQ: Not applicable. Only the few records with a hazardous secondary material, consolidation, or episodic-waste row carry these."
    ),
    dummy = c(
      "Unknown ('U') on the activity flags marks entries whose 'N' predates the flag's existence on the notification form; the recode rules are documented in the 02_modular_master_files README.",
      "INCLUDE_IN_NATIONAL_REPORT: 'U' is shipped by EPA on pre-2001 records.",
      "BR_EXEMPT: 'U' marks a blank exemption flag on a pre-2021 report cycle."
    )
  )
)
