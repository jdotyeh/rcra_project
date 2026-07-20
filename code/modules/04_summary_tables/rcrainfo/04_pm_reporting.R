# =============================================================================
# FILE:     04_pm_reporting.R
# PURPOSE:  Build the Permitting module summary workbook from the PM_MASTER
#           master file, using the shared engine.
# INPUTS:   output/modular_master_files/PM_MASTER.csv; sources 00_function.R
# OUTPUTS:  output/summary_tables/Permitting Module Summary Tables.xlsx
# AUTHOR:   Jason Ye
# CREATED:  2026-07-07
# UPDATED:  2026-07-19
# =============================================================================

# "Permitting Module Summary Tables.xlsx" from PM_MASTER, the Permitting master
# file (one row per permit event x unit detail x waste code x modification
# link), via the shared engine (00_function.R).
#
# The spec covers every column of the master that carries a coded, dated,
# numeric, or indicator value, across the event, the permit series, the unit
# detail, the waste code, and the subsequent-modification link. What is left
# out is the facility identifiers repeated on the unit and modification rows,
# the series and unit names, and the staff identifiers.
#
# The unit-detail block contributes the process, capacity, and status columns
# and two 1/0 indicators, so the workbook carries all three tabs.
#
# Reads output/modular_master_files/PM_MASTER.csv; writes
# output/summary_tables/Permitting Module Summary Tables.xlsx.
# Requires: tidyverse, lubridate, openxlsx2. Run from the repo root.

source("code/modules/04_summary_tables/rcrainfo/00_function.R")

pm_file  <- "output/modular_master_files/PM_MASTER.csv"
out_file <- "output/summary_tables/Permitting Module Summary Tables.xlsx"

# ---- Code labels ------------------------------------------------------------
agency_labels <- c(
  E = "EPA", S = "State",
  J = "Joint with State Lead", P = "Joint with EPA Lead")
owner_labels <- c(
  HQ = "Nationally Defined Values",
  `01` = "EPA Region 1", `02` = "EPA Region 2", `03` = "EPA Region 3",
  `04` = "EPA Region 4", `05` = "EPA Region 5", `06` = "EPA Region 6",
  `07` = "EPA Region 7", `08` = "EPA Region 8", `09` = "EPA Region 9",
  `10` = "EPA Region 10",
  `1` = "EPA Region 1", `2` = "EPA Region 2", `3` = "EPA Region 3",
  `4` = "EPA Region 4", `5` = "EPA Region 5", `6` = "EPA Region 6",
  `7` = "EPA Region 7", `8` = "EPA Region 8", `9` = "EPA Region 9")
event_code_labels <- c(
  OP230OH = "Modification Requested - Other Modification",
  OP240OH = "Modification Approved - Other Modification",
  CL310   = "Plan Received - Closure",
  OP110   = "Revisions Received",
  OP100   = "Notice of Deficiency",
  CL380CA = "Closure Verification - Clean Closure Acceptable",
  OP23110 = "Class Determination - Class 1 Mod, No Prior Approval Required",
  OP23111 = "Class Determination - Class 1 Mod, Prior Approval Required",
  OP236AP = "Modification Public Notice - Intent to Approve",
  OP241   = "Final Modification Effective Date")
# Unit-level code lists, from the module's lookups (PM_LU_PROCESS_CODE,
# PM_LU_LEGAL_OPERATING_STATUS, PM_LU_UNIT_OF_MEASURE).
process_code_labels <- c(
  S01 = "Container", S02 = "Tank Storage", T01 = "Tank Treatment",
  T04 = "Other Treatment", D80 = "Landfill")
legal_status_labels <- c(
  PIOP = "Permitted - Operating", PTBC = "Permit Terminated - Before Construction",
  ISOP = "Interim Status - Operating", PTCC = "Permit Terminated - Clean Closed",
  PIBC = "Permitted - Before Construction")
uom_labels <- c(
  G = "Gallons", U = "Gallons Per Day", C = "Cubic Meters",
  Y = "Cubic Yards", D = "Short Tons Per Hour")
waste_code_labels <- c(
  D001 = "Ignitable Waste", D008 = "Lead", D007 = "Chromium",
  D006 = "Cadmium", D018 = "Benzene")

# ---- Spec -------------------------------------------------------------------
id_col <- "HANDLER_ID"
cat_spec <- list(
  list(col = "EVENT_ACTIVITY_LOCATION", name = "EVENT_ACTIVITY_LOCATION", labels = NULL,
       desc = "State or territory whose implementing agency is responsible for the event."),
  list(col = "EVENT_AGENCY", name = "EVENT_AGENCY", labels = agency_labels,
       desc = "Agency responsible for the permitting event."),
  list(col = "EVENT_OWNER", name = "EVENT_OWNER", labels = owner_labels,
       desc = "Organization that owns the event record."),
  list(col = "EVENT_CODE", name = "EVENT_CODE", labels = event_code_labels,
       desc = "Permit event / milestone code."),
  list(col = "RESPONSIBLE_PERSON_OWNER", name = "RESPONSIBLE_PERSON_OWNER", labels = owner_labels,
       desc = "Organization that owns the record of the person responsible for the event."),
  list(col = "SUBORGANIZATION_OWNER", name = "SUBORGANIZATION_OWNER", labels = owner_labels,
       desc = "Organization that owns the suborganization record on the event."),
  list(col = "SUBORGANIZATION", name = "SUBORGANIZATION", labels = NULL,
       desc = "Suborganization within the implementing agency that handles the event (codes are agency-specific)."),
  list(col = "SERIES_RESPONSIBLE_PERSON_OWNER", name = "SERIES_RESPONSIBLE_PERSON_OWNER", labels = owner_labels,
       desc = "Organization that owns the record of the person responsible for the permit series."),
  list(col = "PROCESS_CODE_OWNER", name = "PROCESS_CODE_OWNER", labels = owner_labels,
       desc = "Organization that defines the process code list."),
  list(col = "PROCESS_CODE", name = "PROCESS_CODE", labels = process_code_labels,
       desc = "Process code of the linked unit (S = storage, T = treatment, D = disposal families)."),
  list(col = "CAPACITY_TYPE", name = "CAPACITY_TYPE", labels = NULL,
       desc = "Type of the reported unit capacity (codes P, O, D)."),
  list(col = "UOM_OWNER", name = "UOM_OWNER", labels = owner_labels,
       desc = "Organization that defines the unit-of-measure code list."),
  list(col = "UOM_TYPE", name = "UOM_TYPE", labels = uom_labels,
       desc = "Unit of measure the capacity is reported in."),
  list(col = "LEGAL_OPERATING_STATUS_OWNER", name = "LEGAL_OPERATING_STATUS_OWNER", labels = owner_labels,
       desc = "Organization that defines the legal-operating-status code list."),
  list(col = "LEGAL_OPERATING_STATUS", name = "LEGAL_OPERATING_STATUS", labels = legal_status_labels,
       desc = "Legal / operating status of the linked process unit."),
  list(col = "COMMERCIAL_STATUS", name = "COMMERCIAL_STATUS", labels = NULL,
       desc = "Commercial availability of the linked process unit (codes 0-3)."),
  list(col = "WASTE_CODE_OWNER", name = "WASTE_CODE_OWNER", labels = owner_labels,
       desc = "Organization that defines the waste code list."),
  list(col = "WASTE_CODE", name = "WASTE_CODE", labels = waste_code_labels,
       desc = "Waste code the linked unit is permitted to manage (one row per code)."),
  list(col = "SUBSEQUENT_MOD_ACTIVITY_LOCATION", name = "SUBSEQUENT_MOD_ACTIVITY_LOCATION", labels = NULL,
       desc = "State or territory responsible for the later modification event linked to this one."),
  list(col = "SUBSEQUENT_MOD_EVENT_AGENCY", name = "SUBSEQUENT_MOD_EVENT_AGENCY", labels = agency_labels,
       desc = "Agency responsible for the later modification event."),
  list(col = "SUBSEQUENT_MOD_EVENT_OWNER", name = "SUBSEQUENT_MOD_EVENT_OWNER", labels = owner_labels,
       desc = "Organization that owns the later modification event record."),
  list(col = "SUBSEQUENT_MOD_EVENT_CODE", name = "SUBSEQUENT_MOD_EVENT_CODE", labels = event_code_labels,
       desc = "Event code of the later modification linked to this event.")
)
quant_dates <- c("ACTUAL_DATE", "SCHEDULE_DATE_ORIG", "SCHEDULE_DATE_NEW",
                 "BEST_DATE", "EFFECTIVE_DATE")
quant_nums  <- c(SERIES_SEQ = 0L, EVENT_SEQ = 0L, UNIT_SEQ = 0L, UNIT_DETAIL_SEQ = 0L,
                 CAPACITY = 2L, NUMBER_OF_UNITS = 0L,
                 SUBSEQUENT_MOD_SERIES_SEQ = 0L, SUBSEQUENT_MOD_EVENT_SEQ = 0L)
flag_simple <- c("STANDARDIZED_PERMIT_IND", "CURRENT_UNIT_DETAIL")

# ---- Load (only the needed columns; the master ships underscore names) -------
need <- needed_columns(cat_spec, quant_dates, quant_nums, flag_simple, id_col = id_col)
all_cols <- read_csv(pm_file, n_max = 0, show_col_types = FALSE) |> names()
pm <- read_csv(pm_file, col_select = all_of(need),
               col_types = cols(.default = col_character()))

build_module_summary(
  data = pm, all_cols = all_cols, out_file = out_file, id_col = id_col,
  temporal_col = "BEST_DATE",
  banner = "Identifier: HANDLER_ID, one row per permit event x unit detail x waste code x subsequent-modification link.",
  cat_spec = cat_spec, quant_dates = quant_dates, quant_nums = quant_nums,
  flag_simple = flag_simple,
  module_desc = "Permitting - events in issuing, modifying, and renewing RCRA permits, mainly held by TSDFs. Summarized from the PM_MASTER master file.",
  missing_notes = list(
    categorical = c(
      "SUBORGANIZATION_OWNER / SUBORGANIZATION: Missing. Only the agencies that record a handling suborganization fill these.",
      "PROCESS_CODE / LEGAL_OPERATING_STATUS / COMMERCIAL_STATUS / CAPACITY_TYPE / UOM_TYPE and their owner columns: Not applicable. Blank on events with no linked unit detail.",
      "WASTE_CODE_OWNER / WASTE_CODE: Not applicable. Only the unit details that list permitted waste codes carry these.",
      "SUBSEQUENT_MOD_*: Not applicable. Only the events that a later modification points back to carry a link."),
    quantitative = c(
      "SCHEDULE_DATE_ORIG: Not applicable. Most events are recorded as completed actuals. Only scheduled events carry a scheduled date.",
      "SCHEDULE_DATE_NEW: Not applicable. Only rescheduled events have a revised date.",
      "EFFECTIVE_DATE / CAPACITY / NUMBER_OF_UNITS / UNIT_SEQ / UNIT_DETAIL_SEQ: Not applicable. Blank on events with no linked unit detail.",
      "SUBSEQUENT_MOD_SERIES_SEQ / SUBSEQUENT_MOD_EVENT_SEQ: Not applicable. Only the events that a later modification points back to carry a link."),
    dummy = c(
      "Both indicators: Missing. Blank on events with no linked unit detail."))
)
