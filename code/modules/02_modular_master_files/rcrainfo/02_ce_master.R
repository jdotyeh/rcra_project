# =============================================================================
# FILE:     02_ce_master.R
# PURPOSE:  Build the Compliance Monitoring and Enforcement module master file by
#           left-joining CE_REPORTING with the CE_CITATION dimension.
# INPUTS:   data/rcrainfo/ce/*.csv (CE_REPORTING, CE_CITATION)
# OUTPUTS:  output/modular_master_files/CE_MASTER.csv
# AUTHOR:   Jason Ye
# CREATED:  2026-07-08
# UPDATED:  2026-07-08
# =============================================================================
#
# Master file for the Compliance, Monitoring & Enforcement (ce) module:
# CE_REPORTING (evaluation x 3007-request x violation x enforcement x SEP
# rows) left-joined with CE_CITATION, which adds the citation dimension
# (CITATION_SEQ, CITATION_OWNER, CITATION, CITATION_TYPE) and the violation
# type owner. One row per evaluation x violation x enforcement x SEP x
# citation combination; every field in the module is kept.
#
# All columns are read as character so zero-padded identifiers (e.g. eval
# identifier "001") and yyyymmdd date stamps survive verbatim.
#
# Requires: tidyverse
# =============================================================================

library(tidyverse)

ce_dir  <- "data/rcrainfo/ce"
out_file <- "output/modular_master_files/CE_MASTER.csv"

read_ce <- function(file) {
  df <- read_csv(file.path(ce_dir, file),
                 col_types = cols(.default = "c"), show_col_types = FALSE)
  names(df) <- gsub(" ", "_", names(df))
  df
}

reporting <- read_ce("CE_REPORTING.csv")
citation  <- read_ce("CE_CITATION.csv") |>
  rename(VIOL_TYPE_OWNER = VIOL_OWNER)

# Violation identity shared by both files; one violation can carry several
# citations, so the join legitimately expands rows.
viol_keys <- c("HANDLER_ID", "VIOL_ACTIVITY_LOCATION", "VIOL_SEQ",
               "VIOL_DETERMINED_BY_AGENCY", "VIOL_TYPE")

master <- reporting |>
  left_join(citation, by = viol_keys, relationship = "many-to-many") |>
  select(
    # Basic information
    HANDLER_ID, EVAL_IDENTIFIER, VIOL_SEQ, ENF_IDENTIFIER,
    REQUEST_SEQ, CITATION_SEQ, CAFO_SEQ, SEP_SEQ,
    # Handler snapshot
    HANDLER_NAME, HANDLER_ACTIVITY_LOCATION, REGION, STATE, LAND_TYPE,
    # Evaluation information
    EVAL_ACTIVITY_LOCATION, EVAL_TYPE, EVAL_TYPE_DESC,
    FOCUS_AREA, FOCUS_AREA_DESC, EVAL_START_DATE, EVAL_AGENCY,
    FOUND_VIOLATION, CITIZEN_COMPLAINT, MULTIMEDIA_INSPECTION, SAMPLING,
    NOT_SUBTITLE_C, NOC_DATE, EVAL_RESPONSIBLE_PERSON, EVAL_SUBORGANIZATION,
    EVAL_LAST_CHANGE,
    # 3007 request information
    DATE_OF_REQUEST, DATE_RESPONSE_RECEIVED, REQUEST_AGENCY,
    REQUEST_ACTIVITY_LOCATION,
    # Violation information
    VIOL_ACTIVITY_LOCATION, VIOL_TYPE_OWNER, VIOL_TYPE, VIOL_SHORT_DESC,
    DETERMINED_DATE, VIOL_DETERMINED_BY_AGENCY, RESPONSIBLE_AGENCY,
    SCHEDULED_COMPLIANCE_DATE, ACTUAL_RTC_DATE, RTC_QUALIFIER,
    CITATION_OWNER, CITATION, CITATION_TYPE, FORMER_CITATION,
    VIOL_LAST_CHANGE,
    # Enforcement information
    ENF_ACTIVITY_LOCATION, ENF_TYPE, ENF_TYPE_DESC, ENF_ACTION_DATE,
    ENF_AGENCY, DOCKET_NUMBER, ATTORNEY, ENF_RESPONSIBLE_PERSON,
    ENF_SUBORGANIZATION, CA_COMPONENT, FA_REQUIREMENT,
    APPEAL_INITIATED_DATE, APPEAL_RESOLVED_DATE,
    DISPOSITION_STATUS, DISPOSITION_STATUS_DESC, DISPOSITION_STATUS_DATE,
    RESPONDENT_NAME, LEAD_AGENCY, ENF_LAST_CHANGE,
    # Penalty & SEP information
    PROPOSED_AMOUNT, FINAL_MONETARY_AMOUNT, PAID_AMOUNT, FINAL_COUNT,
    FINAL_AMOUNT, SEP_TYPE, SEP_TYPE_DESC, EXPENDITURE_AMOUNT,
    SCHEDULED_COMPLETION_DATE, ACTUAL_COMPLETION_DATE, SEP_DEFAULTED_DATE
  )

write_csv(master, out_file, na = "")
