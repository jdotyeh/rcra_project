# =============================================================================
# FILE:     03_ca_event.R
# PURPOSE:  Build the Corrective Action module summary workbook from the raw
#           CA_EVENT table, using the shared engine.
# INPUTS:   data/rcrainfo/ca/CA_EVENT.csv; sources 00_function.R
# OUTPUTS:  output/summary_tables/Corrective Action Module Summary Tables.xlsx
# AUTHOR:   Jason Ye
# CREATED:  2026-07-07
# UPDATED:  2026-07-07
# =============================================================================

# "Corrective Action Module Summary Tables.xlsx" from the raw CA_EVENT table
# (the Corrective Action module's central event log: one row per
# corrective-action event/milestone at a handler), via the shared engine
# (00_function.R), so the workbook is in the same house format as the Handler
# and CME modules.
#
# CA_EVENT has categorical and date variables but no numeric or binary-indicator
# variables, so the engine produces two tabs (Categorical, Quantitative) and
# omits the Dummy tab.
#
# Reads data/rcrainfo/ca/CA_EVENT.csv; writes
# output/summary_tables/Corrective Action Module Summary Tables.xlsx.
# Requires: tidyverse, lubridate, openxlsx2. Run from the repo root.

source("code/modules/04_summary_tables/rcrainfo/00_function.R")

ca_file  <- "data/rcrainfo/ca/CA_EVENT.csv"
out_file <- "output/summary_tables/Corrective Action Module Summary Tables.xlsx"

# ---- Load (CA_EVENT is small; single file) ----------------------------------
ca <- read_csv(ca_file, col_types = cols(.default = col_character())) |>
  rename_with(~ str_replace_all(.x, " ", "_"))
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
  CA110 = "Investigation Workplan Received",
  CA400 = "Remedy Decision",
  CA150 = "Investigation Workplan Approved",
  CA200 = "Investigation Complete",
  CA725YE = "Current Human Exposures Under Control Determination - Under Control"
)

# ---- Spec -------------------------------------------------------------------
cat_spec <- list(
  list(col = "EVENT_AGENCY", name = "EVENT_AGENCY", labels = agency_labels,
       desc = "Agency responsible for the corrective-action event."),
  list(col = "EVENT_ACTIVITY_LOCATION", name = "EVENT_ACTIVITY_LOCATION", labels = NULL,
       desc = "State or territory whose implementing agency is responsible for the event."),
  list(col = "EVENT_OWNER", name = "EVENT_OWNER", labels = owner_labels,
       desc = "Organization that owns the event record (HQ = EPA headquarters; otherwise a state or EPA-region code)."),
  list(col = "EVENT_CODE", name = "EVENT_CODE", labels = event_code_labels,
       desc = "Corrective-action event / milestone code (decoded via CA_LU_EVENT_CODE).")
)
quant_dates <- c("SCHEDULE_DATE_ORIG", "SCHEDULE_DATE_NEW", "ACTUAL_DATE", "BEST_DATE")
# no numeric or binary-indicator variables in CA_EVENT

build_module_summary(
  data         = ca,
  all_cols     = all_cols,
  out_file     = out_file,
  id_col       = "HANDLER_ID",
  temporal_col = "BEST_DATE",
  banner       = "Identifier: HANDLER_ID, one row per corrective-action event.",
  cat_spec     = cat_spec,
  quant_dates  = quant_dates,
  module_desc  = "Corrective Action - investigation and cleanup events at facilities required to remediate hazardous-waste releases.",
  missing_notes = list(
    quantitative = c(
      "SCHEDULE_DATE_ORIG: Not applicable. Most events are recorded as completed actuals. Only scheduled events have a scheduled date.",
      "SCHEDULE_DATE_NEW: Not applicable. Only rescheduled events have a revised date."))
)
