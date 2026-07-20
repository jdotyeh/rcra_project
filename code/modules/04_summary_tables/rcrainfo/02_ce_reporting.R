# =============================================================================
# FILE:     02_ce_reporting.R
# PURPOSE:  Build the Compliance Monitoring and Enforcement (CME) module summary
#           workbook from the CE_MASTER master file, using the shared engine.
# INPUTS:   output/modular_master_files/CE_MASTER.csv; sources 00_function.R
# OUTPUTS:  output/summary_tables/CME Module Summary Tables.xlsx
# AUTHOR:   Jason Ye
# CREATED:  2026-07-07
# UPDATED:  2026-07-19
# =============================================================================

# "CME Module Summary Tables.xlsx" from CE_MASTER, the Compliance Monitoring &
# Enforcement master file (one row per evaluation x violation x enforcement x
# SEP x citation), via the shared engine (00_function.R).
#
# The spec covers every column of the master that carries a coded, dated,
# numeric, or indicator value, which here means all five blocks of the file,
# the evaluation, the information request, the violation, the enforcement
# action, and the supplemental environmental project. What is left out is the
# site name, the evaluation and enforcement identifiers, the docket number, the
# staff and attorney identifiers, the respondent name, the former-citation
# text, and the description columns that label a code summarized here.
#
# Categorical labels are derived at runtime from the paired in-data "_DESC"
# columns (labels = "desc:<COL>"). The master codes its flags 1/0;
# FOUND_VIOLATION also carries "U" (undetermined) and lands on the Dummy tab's
# Unknown columns.
#
# Reads output/modular_master_files/CE_MASTER.csv; writes
# output/summary_tables/CME Module Summary Tables.xlsx.
# Requires: tidyverse, lubridate, openxlsx2. Run from the repo root.

source("code/modules/04_summary_tables/rcrainfo/00_function.R")

ce_file  <- "output/modular_master_files/CE_MASTER.csv"
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
# Citation type separates federal from state law and both from permit conditions.
lab_citation_type <- c(FR = "Federal Regulation", SR = "State Regulation",
                       SS = "State Statute", FS = "Federal Statute",
                       PC = "Permit Condition", OC = "Order Condition")
lab_owner <- c(HQ = "Nationally Defined Values")

# ---- Spec -------------------------------------------------------------------
id_col <- "HANDLER_ID"
cat_spec <- list(
  list(col = "HANDLER_ACTIVITY_LOCATION", name = "HANDLER_ACTIVITY_LOCATION", labels = NULL,
       desc = "State or territory whose implementing agency is responsible for the site."),
  list(col = "REGION", name = "REGION", labels = NULL,
       desc = "EPA region in which the site is located."),
  list(col = "STATE", name = "STATE", labels = NULL,
       desc = "State in which the site is located."),
  list(col = "LAND_TYPE", name = "LAND_TYPE", labels = lab_land,
       desc = "Ownership type of the land on which the site is located."),
  list(col = "EVAL_ACTIVITY_LOCATION", name = "EVAL_ACTIVITY_LOCATION", labels = NULL,
       desc = "State or territory whose implementing agency is responsible for the evaluation."),
  list(col = "EVAL_TYPE", name = "EVAL_TYPE", labels = "desc:EVAL_TYPE_DESC",
       desc = "Type of compliance evaluation performed."),
  list(col = "FOCUS_AREA", name = "FOCUS_AREA", labels = "desc:FOCUS_AREA_DESC",
       desc = "Regulatory area the evaluation concentrated on."),
  list(col = "EVAL_AGENCY", name = "EVAL_AGENCY", labels = agency_labels,
       desc = "Agency that conducted the compliance evaluation."),
  list(col = "EVAL_SUBORGANIZATION", name = "EVAL_SUBORGANIZATION", labels = NULL,
       desc = "Suborganization within the evaluating agency (codes are agency-specific)."),
  list(col = "REQUEST_AGENCY", name = "REQUEST_AGENCY", labels = agency_labels,
       desc = "Agency that issued the information request."),
  list(col = "REQUEST_ACTIVITY_LOCATION", name = "REQUEST_ACTIVITY_LOCATION", labels = NULL,
       desc = "State or territory whose implementing agency is responsible for the information request."),
  list(col = "VIOL_ACTIVITY_LOCATION", name = "VIOL_ACTIVITY_LOCATION", labels = NULL,
       desc = "State or territory whose implementing agency is responsible for the violation."),
  list(col = "VIOL_TYPE_OWNER", name = "VIOL_TYPE_OWNER", labels = lab_owner,
       desc = "Organization that defines the violation-type code list."),
  list(col = "VIOL_TYPE", name = "VIOL_TYPE", labels = "desc:VIOL_SHORT_DESC",
       desc = "Regulatory area of the violation."),
  list(col = "VIOL_DETERMINED_BY_AGENCY", name = "VIOL_DETERMINED_BY_AGENCY", labels = agency_labels,
       desc = "Agency that determined the violation."),
  list(col = "RESPONSIBLE_AGENCY", name = "RESPONSIBLE_AGENCY", labels = agency_labels,
       desc = "Agency responsible for bringing the site back into compliance."),
  list(col = "RTC_QUALIFIER", name = "RTC_QUALIFIER", labels = NULL,
       desc = "Qualifier on how the violation was returned to compliance."),
  list(col = "CITATION_OWNER", name = "CITATION_OWNER", labels = lab_owner,
       desc = "Organization that defines the citation code list."),
  list(col = "CITATION", name = "CITATION", labels = NULL,
       desc = "Regulation, statute, or permit condition the violation was written under."),
  list(col = "CITATION_TYPE", name = "CITATION_TYPE", labels = lab_citation_type,
       desc = "Whether the citation is federal, state, or permit-based."),
  list(col = "ENF_ACTIVITY_LOCATION", name = "ENF_ACTIVITY_LOCATION", labels = NULL,
       desc = "State or territory whose implementing agency is responsible for the enforcement action."),
  list(col = "ENF_TYPE", name = "ENF_TYPE", labels = "desc:ENF_TYPE_DESC",
       desc = "Type of enforcement action taken."),
  list(col = "ENF_AGENCY", name = "ENF_AGENCY", labels = agency_labels,
       desc = "Agency that took the enforcement action."),
  list(col = "ENF_SUBORGANIZATION", name = "ENF_SUBORGANIZATION", labels = NULL,
       desc = "Suborganization within the enforcing agency (codes are agency-specific)."),
  list(col = "DISPOSITION_STATUS", name = "DISPOSITION_STATUS", labels = "desc:DISPOSITION_STATUS_DESC",
       desc = "Where the enforcement action stands."),
  list(col = "LEAD_AGENCY", name = "LEAD_AGENCY", labels = NULL,
       desc = "Agency leading a case handled jointly."),
  list(col = "SEP_TYPE", name = "SEP_TYPE", labels = "desc:SEP_TYPE_DESC",
       desc = "Type of supplemental environmental project accepted in settlement.")
)
quant_dates <- c("EVAL_START_DATE", "NOC_DATE", "EVAL_LAST_CHANGE",
                 "DATE_OF_REQUEST", "DATE_RESPONSE_RECEIVED",
                 "DETERMINED_DATE", "SCHEDULED_COMPLIANCE_DATE", "ACTUAL_RTC_DATE",
                 "VIOL_LAST_CHANGE", "ENF_ACTION_DATE",
                 "APPEAL_INITIATED_DATE", "APPEAL_RESOLVED_DATE",
                 "DISPOSITION_STATUS_DATE", "ENF_LAST_CHANGE",
                 "SCHEDULED_COMPLETION_DATE", "ACTUAL_COMPLETION_DATE",
                 "SEP_DEFAULTED_DATE")
quant_nums  <- c(VIOL_SEQ = 0L, REQUEST_SEQ = 0L, CITATION_SEQ = 0L,
                 CAFO_SEQ = 0L, SEP_SEQ = 0L,
                 PROPOSED_AMOUNT = 2L, FINAL_MONETARY_AMOUNT = 2L,
                 PAID_AMOUNT = 2L, FINAL_COUNT = 0L, FINAL_AMOUNT = 2L,
                 EXPENDITURE_AMOUNT = 2L)
flag_simple <- c("FOUND_VIOLATION", "CITIZEN_COMPLAINT", "MULTIMEDIA_INSPECTION",
                 "SAMPLING", "NOT_SUBTITLE_C", "CA_COMPONENT", "FA_REQUIREMENT")

# ---- Load (only the needed columns; the master ships underscore names) -------
need <- needed_columns(cat_spec, quant_dates, quant_nums, flag_simple, id_col = id_col)
all_cols <- read_csv(ce_file, n_max = 0, show_col_types = FALSE) |> names()
ce <- read_csv(ce_file, col_select = all_of(need),
               col_types = cols(.default = col_character()))

build_module_summary(
  data = ce, all_cols = all_cols, out_file = out_file, id_col = id_col,
  temporal_col = "EVAL_START_DATE",
  banner = "Identifier: HANDLER_ID, one row per evaluation x violation x enforcement x SEP x citation combination.",
  cat_spec = cat_spec, quant_dates = quant_dates, quant_nums = quant_nums,
  flag_simple = flag_simple,
  module_desc = "Compliance Monitoring & Enforcement - evaluations of hazardous-waste handlers, the violations found, and the enforcement actions taken. Summarized from the CE_MASTER master file.",
  missing_notes = list(
    categorical = c(
    "FOCUS_AREA: Not applicable. Only the evaluations that targeted one regulatory area carry a focus.",
    "REQUEST_AGENCY / REQUEST_ACTIVITY_LOCATION: Not applicable. Few evaluations involve a formal information request.",
    "VIOL_TYPE: Not applicable. No violation was found.",
    "RTC_QUALIFIER: Not applicable. Set only once a violation has been returned to compliance.",
    "CITATION / CITATION_TYPE / CITATION_OWNER: Not applicable. Only violations written to a specific citation carry these.",
    "ENF_TYPE: Not applicable. No enforcement action followed.",
    "DISPOSITION_STATUS / LEAD_AGENCY: Not applicable. Recorded on the formal actions that reach a disposition.",
    "SEP_TYPE: Not applicable. Very few settlements include a supplemental environmental project.",
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
      "NOC_DATE: Not applicable. Only the evaluations that produced a notice of correction carry one.",
      "DATE_OF_REQUEST / DATE_RESPONSE_RECEIVED / REQUEST_SEQ: Not applicable. Few evaluations involve a formal information request.",
      "DETERMINED_DATE: Not applicable. These are the evaluations that didn't find a violation.",
      "SCHEDULED_COMPLIANCE_DATE: Not applicable. Set only where the agency scheduled a compliance date for the violation.",
      "ACTUAL_RTC_DATE: Missing. Either incomplete reporting or the agency hasn't designated RTC status yet.",
      "ENF_ACTION_DATE: Not applicable. These are the evaluations that didn't have an enforcement action followed.",
      "APPEAL_INITIATED_DATE / APPEAL_RESOLVED_DATE: Not applicable. Very few enforcement actions are appealed.",
      "DISPOSITION_STATUS_DATE: Not applicable. Recorded on the formal actions that reach a disposition.",
      "PROPOSED_AMOUNT: Not applicable. Not all enforcement actions have a proposed penalty, even the enforcement action has a penalty.",
      "FINAL_MONETARY_AMOUNT: Not applicable. Not all enforcement actions have a monetary penalty.",
      "PAID_AMOUNT: Not applicable or missing. Most likely because not all penalties are paid.",
      "FINAL_COUNT: Not applicable. It counts the final monetary order on the action, so it reads 1 wherever a final amount exists.",
      "FINAL_AMOUNT: Not applicable. N is larger than FINAL_MONETARY_AMOUNT because it reports the total penalties (final monetary penalty + Supplemental Environmental Project credit).",
      "SEP_SEQ / EXPENDITURE_AMOUNT / SCHEDULED_COMPLETION_DATE / ACTUAL_COMPLETION_DATE / SEP_DEFAULTED_DATE: Not applicable. Very few settlements include a supplemental environmental project, and fewer still default on one.",
      "CAFO_SEQ: Not applicable. Only the actions issued as a combined complaint and final order carry one."
    ),
    dummy = c(
      "FOUND_VIOLATION: Unknown ('U') is EPA's own undetermined code.",
      "CA_COMPONENT: Missing. Incomplete reporting.",
      "FA_REQUIREMENT: Missing, but more likely 0."
    )
  )
)
