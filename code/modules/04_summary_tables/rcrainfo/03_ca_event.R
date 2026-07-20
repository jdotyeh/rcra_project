# =============================================================================
# FILE:     03_ca_event.R
# PURPOSE:  Build the Corrective Action module summary workbook from the
#           CA_MASTER master file, using the shared engine.
# INPUTS:   output/modular_master_files/CA_MASTER.csv; sources 00_function.R
# OUTPUTS:  output/summary_tables/Corrective Action Module Summary Tables.xlsx
# AUTHOR:   Jason Ye
# CREATED:  2026-07-07
# UPDATED:  2026-07-19
# =============================================================================

# "Corrective Action Module Summary Tables.xlsx" from CA_MASTER, the Corrective
# Action master file (one row per event x area x process unit x authority x
# citation), via the shared engine (00_function.R), so the workbook is in the
# same house format as the Handler and CME modules.
#
# The spec covers every column of the master that carries a coded, dated,
# numeric, or indicator value, across all four blocks of the file, the event,
# the area, the process unit, and the legal authority. What is left out is the
# facility identifiers repeated on the area, unit, and authority rows, the area
# name, the staff identifiers, and the public notes.
#
# The master's area block contributes 1/0 release and facility indicators, so
# the workbook carries all three tabs (Categorical, Quantitative, Dummy).
#
# Reads output/modular_master_files/CA_MASTER.csv; writes
# output/summary_tables/Corrective Action Module Summary Tables.xlsx.
# Requires: tidyverse, lubridate, openxlsx2. Run from the repo root.

source("code/modules/04_summary_tables/rcrainfo/00_function.R")

ca_file  <- "output/modular_master_files/CA_MASTER.csv"
out_file <- "output/summary_tables/Corrective Action Module Summary Tables.xlsx"

# ---- Load (CA_MASTER is small; single file) ----------------------------------
ca <- read_csv(ca_file, col_types = cols(.default = col_character()))
all_cols <- names(ca)

agency_labels <- c(
  E = "EPA",
  S = "State",
  J = "Joint with State Lead",
  P = "Joint with EPA Lead"
)

owner_labels <- c(
  HQ = "Nationally Defined Values",
  "01" = "EPA Region 1",
  "02" = "EPA Region 2",
  "03" = "EPA Region 3",
  "04" = "EPA Region 4",
  "05" = "EPA Region 5",
  "06" = "EPA Region 6",
  "07" = "EPA Region 7",
  "08" = "EPA Region 8",
  "09" = "EPA Region 9",
  "10" = "EPA Region 10",
  "1"  = "EPA Region 1",
  "2"  = "EPA Region 2",
  "3"  = "EPA Region 3",
  "4"  = "EPA Region 4",
  "5"  = "EPA Region 5",
  "6"  = "EPA Region 6",
  "7"  = "EPA Region 7",
  "8"  = "EPA Region 8",
  "9"  = "EPA Region 9"
)

# EVENT_CODE values (e.g. CA110) are opaque acronyms; decoded with short
# descriptions from the module's code lookup (CA_LU_EVENT_CODE).
event_code_labels <- c(
  CA100 = "Investigation Imposition",
  CA110 = "Investigation Workplan Received",
  CA150 = "Investigation Workplan Approved",
  CA200 = "Investigation Complete",
  CA400 = "Remedy Decision",
  CA725YE = "Current Human Exposures Under Control Determination - Under Control"
)

# AUTHORITY_TYPE codes, from the module's authority lookup (CA_LU_AUTHORITY).
authority_type_labels <- c(
  O = "Operating Permit", A = "Consent Order", P = "Post-Closure Permit",
  V = "Voluntary CA", Z = "Other", M = "Permit Modification",
  N = "Order Modification", R = "State Unilateral Order",
  J = "Judicial Order", H = "HSWA-only Permit"
)

# ---- Spec -------------------------------------------------------------------
cat_spec <- list(
  list(col = "EVENT_ACTIVITY_LOCATION", name = "EVENT_ACTIVITY_LOCATION", labels = NULL,
       desc = "State or territory whose implementing agency is responsible for the event."),
  list(col = "EVENT_AGENCY", name = "EVENT_AGENCY", labels = agency_labels,
       desc = "Agency responsible for the corrective-action event."),
  list(col = "EVENT_OWNER", name = "EVENT_OWNER", labels = owner_labels,
       desc = "Organization that owns the event record (HQ = EPA headquarters; otherwise a state or EPA-region code)."),
  list(col = "EVENT_CODE", name = "EVENT_CODE", labels = event_code_labels,
       desc = "Corrective-action event / milestone code (decoded via CA_LU_EVENT_CODE)."),
  list(col = "RESPONSIBLE_PERSON_OWNER", name = "RESPONSIBLE_PERSON_OWNER", labels = owner_labels,
       desc = "Organization that owns the record of the person responsible for the event."),
  list(col = "SUBORGANIZATION_OWNER", name = "SUBORGANIZATION_OWNER", labels = owner_labels,
       desc = "Organization that owns the suborganization record on the event."),
  list(col = "SUBORGANIZATION", name = "SUBORGANIZATION", labels = NULL,
       desc = "Suborganization within the implementing agency that handles the event (codes are agency-specific)."),
  list(col = "EPA_OWNER", name = "EPA_OWNER", labels = owner_labels,
       desc = "EPA region that owns the record of the EPA contact for the area."),
  list(col = "STATE_OWNER", name = "STATE_OWNER", labels = owner_labels,
       desc = "State that owns the record of the state contact for the area."),
  list(col = "AUTHORITY_ACTIVITY_LOCATION", name = "AUTHORITY_ACTIVITY_LOCATION", labels = NULL,
       desc = "State or territory whose implementing agency is responsible for the legal authority."),
  list(col = "AUTHORITY_AGENCY", name = "AUTHORITY_AGENCY", labels = agency_labels,
       desc = "Agency behind the legal authority that ordered the event."),
  list(col = "AUTHORITY_OWNER", name = "AUTHORITY_OWNER", labels = owner_labels,
       desc = "Organization that defines the authority code list."),
  list(col = "AUTHORITY_TYPE", name = "AUTHORITY_TYPE", labels = authority_type_labels,
       desc = "Type of legal authority (order, permit, statute) behind the event."),
  list(col = "AUTHORITY_REPOSITORY", name = "AUTHORITY_REPOSITORY", labels = NULL,
       desc = "Repository code recording where the authority document is held."),
  list(col = "AUTHORITY_RESPONSIBLE_PERSON_OWNER", name = "AUTHORITY_RESPONSIBLE_PERSON_OWNER", labels = owner_labels,
       desc = "Organization that owns the record of the person responsible for the authority."),
  list(col = "AUTHORITY_SUBORGANIZATION_OWNER", name = "AUTHORITY_SUBORGANIZATION_OWNER", labels = owner_labels,
       desc = "Organization that owns the suborganization record on the authority."),
  list(col = "AUTHORITY_SUBORGANIZATION", name = "AUTHORITY_SUBORGANIZATION", labels = NULL,
       desc = "Suborganization within the agency that administers the authority (codes are agency-specific)."),
  list(col = "STATUTORY_OWNER", name = "STATUTORY_OWNER", labels = owner_labels,
       desc = "Organization that defines the statutory-citation code list."),
  list(col = "STATUTORY_CITATION", name = "STATUTORY_CITATION", labels = NULL,
       desc = "Statutory citation the authority rests on (the module lookup ships these codes without descriptions).")
)
quant_dates <- c("SCHEDULE_DATE_ORIG", "SCHEDULE_DATE_NEW", "ACTUAL_DATE", "BEST_DATE",
                 "AUTHORITY_EFFECTIVE_DATE", "AUTHORITY_ISSUE_DATE", "AUTHORITY_END_DATE")
quant_nums  <- c(EVENT_SEQ = 0L, AREA_SEQ = 0L, UNIT_SEQ = 0L, AREA_ACREAGE = 2L)
flag_simple <- c("ENTIRE_FACILITY_IND", "REGULATED_UNIT_IND",
                 "AIR_RELEASE_IND", "GROUNDWATER_RELEASE_IND",
                 "SOIL_RELEASE_IND", "SURFACE_WATER_RELEASE_IND")

build_module_summary(
  data         = ca,
  all_cols     = all_cols,
  out_file     = out_file,
  id_col       = "HANDLER_ID",
  temporal_col = "BEST_DATE",
  banner       = "Identifier: HANDLER_ID, one row per corrective-action event x area x process unit x authority x citation combination.",
  cat_spec     = cat_spec,
  quant_dates  = quant_dates,
  quant_nums   = quant_nums,
  flag_simple  = flag_simple,
  module_desc  = "Corrective Action - investigation and cleanup events at facilities required to remediate hazardous-waste releases. Summarized from the CA_MASTER master file.",
  missing_notes = list(
    categorical = c(
      "SUBORGANIZATION_OWNER / SUBORGANIZATION: Missing. Only the agencies that record a handling suborganization fill these.",
      "EPA_OWNER / STATE_OWNER: Not applicable. Each area names at most one of the two contacts, so both columns are blank on most rows.",
      "AUTHORITY_AGENCY / AUTHORITY_TYPE / AUTHORITY_OWNER: Not applicable. Events with no linked authority keep those columns blank.",
      "AUTHORITY_REPOSITORY: Missing. Recorded only where the agency logged where the document is held.",
      "STATUTORY_OWNER / STATUTORY_CITATION: Not applicable. Blank when the event has no linked authority."),
    quantitative = c(
      "SCHEDULE_DATE_ORIG: Not applicable. Most events are recorded as completed actuals. Only scheduled events have a scheduled date.",
      "SCHEDULE_DATE_NEW: Not applicable. Only rescheduled events have a revised date.",
      "UNIT_SEQ: Not applicable. Very few events link to a specific process unit.",
      "AUTHORITY_* dates / AREA_ACREAGE: Not applicable. Blank when the event has no linked authority or area."),
    dummy = c(
      "All six indicators: Missing. Blank when the event has no linked area, and on area rows with incomplete reporting."))
)
