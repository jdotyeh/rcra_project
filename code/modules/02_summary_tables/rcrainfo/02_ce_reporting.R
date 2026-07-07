# "CME Module Summary Tables.xlsx" from the raw CE_REPORTING table (Compliance
# Monitoring & Enforcement; one row per evaluation x violation x enforcement),
# via the shared engine (00_engine.R).
#
# Categorical labels are derived at runtime from the paired in-data "_DESC"
# columns (labels = "desc:<COL>").
#
# Reads data/rcrainfo/ce/CE_REPORTING.csv; writes
# output/summary_tables/CME Module Summary Tables.xlsx.
# Requires: tidyverse, lubridate, openxlsx2. Run from the repo root.

source("code/modules/02_summary_tables/rcrainfo/00_engine.R")

ce_file  <- "data/rcrainfo/ce/CE_REPORTING.csv"
out_file <- "output/summary_tables/CME Module Summary Tables.xlsx"

lab_land  <- c(P = "Private", C = "County", D = "District", F = "Federal",
               I = "Indian/Tribal", M = "Municipal", S = "State", O = "Other")
agency_labels <- c(
  B = "State Contractor/Grantee",
  C = "EPA Contractor/Grantee",
  E = "EPA",
  L = "Local",
  N = "Native American",
  S = "State",
  T = "State-Initiated Oversight/Observation/Training Actions",
  X = "EPA-Initiated Oversight/Observation/Training Actions"
)

# ---- Spec -------------------------------------------------------------------
id_col <- "HANDLER_ID"
cat_spec <- list(
  list(col = "EVAL_AGENCY", name = "EVAL_AGENCY", labels = agency_labels,
       desc = "Agency that conducted the compliance evaluation."),
  list(col = "EVAL_TYPE", name = "EVAL_TYPE", labels = "desc:EVAL_TYPE_DESC",
       desc = "Type of compliance evaluation performed."),
  list(col = "FOUND_VIOLATION", name = "FOUND_VIOLATION",
       labels = c(Y = "Violation Found", N = "No Violation", U = "Undetermined"),
       desc = "Whether the evaluation found a violation."),
  list(col = "REGION", name = "REGION", labels = NULL,
       desc = "EPA region in which the site is located."),
  list(col = "EVAL_ACTIVITY_LOCATION", name = "EVAL_ACTIVITY_LOCATION", labels = NULL,
       desc = "State or territory whose implementing agency is responsible for the evaluation."),
  list(col = "LAND_TYPE", name = "LAND_TYPE", labels = lab_land,
       desc = "Ownership type of the land on which the site is located."),
  list(col = "VIOL_TYPE", name = "VIOL_TYPE", labels = "desc:VIOL_SHORT_DESC",
       desc = "Regulatory area of the violation."),
  list(col = "ENF_TYPE", name = "ENF_TYPE", labels = "desc:ENF_TYPE_DESC",
       desc = "Type of enforcement action taken.")
)
quant_dates <- c("EVAL_START_DATE", "DETERMINED_DATE", "ACTUAL_RTC_DATE",
                 "ENF_ACTION_DATE", "EVAL_LAST_CHANGE")
quant_nums  <- c(PROPOSED_AMOUNT = 2L, FINAL_MONETARY_AMOUNT = 2L,
                 PAID_AMOUNT = 2L, FINAL_AMOUNT = 2L)
flag_simple <- c("CITIZEN_COMPLAINT", "MULTIMEDIA_INSPECTION", "SAMPLING",
                 "NOT_SUBTITLE_C", "CA_COMPONENT", "FA_REQUIREMENT")

# ---- Load (only the needed columns) -----------------------------------------
need <- needed_columns(cat_spec, quant_dates, quant_nums, flag_simple, id_col = id_col)
all_cols <- read_csv(ce_file, n_max = 0, show_col_types = FALSE) |>
  names() |> str_replace_all(" ", "_")
ce <- read_csv(ce_file, col_select = all_of(str_replace_all(need, "_", " ")),
               col_types = cols(.default = col_character())) |>
  rename_with(~ str_replace_all(.x, " ", "_"))

build_module_summary(
  gsheet_id = "1jmTBwPaubl5XmoORIVLgIu7bc6rlLd0HMMJX64RT_MY",
  data = ce, all_cols = all_cols, out_file = out_file, id_col = id_col,
  temporal_col = "EVAL_START_DATE",
  banner = "Identifier: HANDLER_ID, one row per evaluation x violation x enforcement action.",
  cat_spec = cat_spec, quant_dates = quant_dates, quant_nums = quant_nums,
  flag_simple = flag_simple,
  module_desc = "Compliance Monitoring & Enforcement - evaluations of hazardous-waste handlers, the violations found, and the enforcement actions taken.",
  missing_notes = list(
    categorical = c(
    "VIOL_TYPE: Not applicable. No violation was found.",
    "ENF_TYPE: Not applicable. No enforcement action followed.",
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
      "DETERMINED_DATE: Not applicable. These are the evaluations that didn't find a violation.",
      "ACTUAL_RTC_DATE: Missing. Either incomplete reporting or the agency hasn't designated RTC status yet.",
      "ENF_ACTION_DATE: Not applicable. These are the evaluations that didn't have an enforcement action followed.",
      "PROPOSED_AMOUNT: Not applicable. Not all enforcement actions have a proposed penalty, even the enforcement action has a penalty.",
      "FINAL_MONETARY_AMOUNT: Not applicable. Not all enforcement actions have a monetary penalty.",
      "PAID_AMOUNT: Not applicable or missing. Most likely because not all penalties are paid.",
      "FINAL_AMOUNT: Not applicable. N is larger than FINAL_MONETARY_AMOUNT because it reports the total penalties (final monetary penalty + Supplemental Environmental Project credit)."
    ),
    dummy = c(
      "CA_COMPONENT: Missing. Incomplete reporting.",
      "FA_REQUIREMENT: Missing, but more likely N."
    )
  )
)
