# =============================================================================
# FILE:     04_pm_reporting.R
# PURPOSE:  Build the Permitting module summary workbook from the raw PM_EVENT
#           table, using the shared engine.
# INPUTS:   data/rcrainfo/pm/PM_EVENT.csv; sources 00_function.R
# OUTPUTS:  output/summary_tables/Permitting Module Summary Tables.xlsx
# AUTHOR:   Jason Ye
# CREATED:  2026-07-07
# UPDATED:  2026-07-07
# =============================================================================

# "Permitting Module Summary Tables.xlsx" from the raw PM_EVENT table, via the
# shared engine (00_function.R). One row per permit event.
#
# Reads data/rcrainfo/pm/PM_EVENT.csv; writes
# output/summary_tables/Permitting Module Summary Tables.xlsx.
# Requires: tidyverse, lubridate, openxlsx2. Run from the repo root.

source("code/modules/04_summary_tables/rcrainfo/00_function.R")

pm_file  <- "data/rcrainfo/pm/PM_EVENT.csv"
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
  OP23110 = "Class Determination - Class 1 Mod, No Prior Approval Required")

# ---- Spec -------------------------------------------------------------------
id_col <- "HANDLER_ID"
cat_spec <- list(
  list(col = "EVENT_AGENCY", name = "EVENT_AGENCY", labels = agency_labels,
       desc = "Agency responsible for the permitting event."),
  list(col = "EVENT_ACTIVITY_LOCATION", name = "EVENT_ACTIVITY_LOCATION", labels = NULL,
       desc = "State or territory whose implementing agency is responsible for the event."),
  list(col = "EVENT_OWNER", name = "EVENT_OWNER", labels = owner_labels,
       desc = "Organization that owns the event record."),
  list(col = "EVENT_CODE", name = "EVENT_CODE", labels = event_code_labels,
       desc = "Permit event / milestone code."),
  list(col = "SUBORGANIZATION_OWNER", name = "SUBORGANIZATION_OWNER", labels = owner_labels,
       desc = "Owner of the suborganization code."),
  list(col = "SUBORGANIZATION", name = "SUBORGANIZATION", labels = NULL,
       desc = "Suborganization code assigned to the permitting event."),
  list(col = "RESPONSIBLE_PERSON_OWNER", name = "RESPONSIBLE_PERSON_OWNER", labels = owner_labels,
       desc = "Owner of the responsible-person code."),
  list(col = "RESPONSIBLE_PERSON", name = "RESPONSIBLE_PERSON", labels = NULL,
       desc = "Responsible-person code assigned to the permitting event.")
)
quant_dates <- c("ACTUAL_DATE", "SCHEDULE_DATE_ORIG", "SCHEDULE_DATE_NEW", "BEST_DATE")
# no numeric or binary-indicator variables in PM_EVENT

# ---- Load (only the needed columns) -----------------------------------------
need <- needed_columns(cat_spec, quant_dates, id_col = id_col)
all_cols <- read_csv(pm_file, n_max = 0, show_col_types = FALSE) |>
  names() |> str_replace_all(" ", "_")
pm <- read_csv(pm_file, col_select = all_of(str_replace_all(need, "_", " ")),
               col_types = cols(.default = col_character())) |>
  rename_with(~ str_replace_all(.x, " ", "_"))

build_module_summary(
  data = pm, all_cols = all_cols, out_file = out_file, id_col = id_col,
  temporal_col = "BEST_DATE",
  banner = "Identifier: HANDLER_ID, one row per permit event.",
  cat_spec = cat_spec, quant_dates = quant_dates,
  module_desc = "Permitting - events in issuing, modifying, and renewing RCRA permits, mainly held by TSDFs.",
  missing_notes = list(
    categorical = c(
      "SUBORGANIZATION / SUBORGANIZATION_OWNER: Not determinable.",
      "RESPONSIBLE_PERSON / RESPONSIBLE_PERSON_OWNER: Not determinable."),
    quantitative = c(
      "SCHEDULE_DATE_ORIG: Not applicable. Most events are recorded as completed actuals. Only scheduled events carry a scheduled date.",
      "SCHEDULE_DATE_NEW: Not applicable. Only rescheduled events have a revised date."))
)
