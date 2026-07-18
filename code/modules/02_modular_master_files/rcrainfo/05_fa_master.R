# =============================================================================
# FILE:     05_fa_master.R
# PURPOSE:  Build the Financial Assurance module master file by joining
#           FA_COST_ESTIMATE to the financial mechanism that funds it.
# INPUTS:   data/rcrainfo/fa/*.csv (FA_COST_ESTIMATE plus its dimension tables);
#           sources 00_function.R
# OUTPUTS:  output/modular_master_files/FA_MASTER.csv
# AUTHOR:   Jason Ye
# CREATED:  2026-07-08
# UPDATED:  2026-07-17
# =============================================================================
#
# Master file for the Financial Assurance (fa) module:
# FA_COST_ESTIMATE (one row per handler x FA-type x coverage: what a facility
# must be able to pay for) joined to the financial mechanism that funds it. One
# row per cost estimate x linked mechanism detail; left joins throughout, so a
# cost estimate with no mechanism on file keeps one row with the mechanism
# columns blank.
#
#   FA_COST_MECHANISM_DETAIL  cost estimate -> mechanism-detail link (by the
#                             cost-estimate key)
#   FA_MECHANISM_DETAIL       the mechanism detail: total & facility face value,
#                             effective / expiration dates, financial-test
#                             alternative, current flag
#   FA_MECHANISM              the mechanism: type and provider (institution,
#                             contact name / phone / email)
#
# All columns are read as character so zero-padded identifiers, dollar amounts,
# and yyyymmdd date stamps survive verbatim. The two current-record Y/N flags
# are recoded to integer 1/0 (see the module README).
#
# Requires: tidyverse
# =============================================================================

# Shared master-file helpers: read_module() and convert_indicators().
# Loads tidyverse.
source("code/modules/02_modular_master_files/rcrainfo/00_function.R")

fa_dir   <- "data/rcrainfo/fa"
out_file <- "output/modular_master_files/FA_MASTER.csv"

read_fa <- function(file) read_module(fa_dir, file)

# Cost-estimate identity. FA_COST_ESTIMATE spells the handler key HANDLER_ID;
# the link table prefixes it COST_.
cost_keys <- c("COST_ACTIVITY_LOCATION", "COST_FA_TYPE", "COST_AGENCY",
               "COST_COVERAGE_SEQ")
# Mechanism-detail identity, shared by the link, detail, and mechanism tables.
mech_keys        <- c("MECH_ACTIVITY_LOCATION", "MECH_AGENCY", "MECH_SEQ")
mech_detail_keys <- c(mech_keys, "MECH_DETAIL_SEQ")

cost_estimate  <- read_fa("FA_COST_ESTIMATE.csv") |>
  convert_indicators("CURRENT_COST_ESTIMATE")
cost_mechanism <- read_fa("FA_COST_MECHANISM_DETAIL.csv")
mech_detail    <- read_fa("FA_MECHANISM_DETAIL.csv") |>
  convert_indicators("CURRENT_MECHANISM_DETAIL")
mechanism      <- read_fa("FA_MECHANISM.csv")

master <- cost_estimate |>
  # cost estimate -> the mechanism detail(s) that fund it
  left_join(cost_mechanism, by = c("HANDLER_ID" = "COST_HANDLER_ID", cost_keys),
            relationship = "many-to-many") |>
  left_join(mech_detail,
            by = c("MECH_HANDLER_ID" = "HANDLER_ID", mech_detail_keys),
            relationship = "many-to-many") |>
  left_join(mechanism,
            by = c("MECH_HANDLER_ID" = "HANDLER_ID", mech_keys),
            relationship = "many-to-many")

master <- master |>
  select(
    # Cost-estimate identity
    HANDLER_ID, COST_ACTIVITY_LOCATION, COST_FA_TYPE, COST_AGENCY,
    COST_COVERAGE_SEQ,
    # Cost-estimate information
    COST_ESTIMATE_AMOUNT, COST_ESTIMATE_DATE, COST_ESTIMATE_REASON,
    UPDATE_DUE_DATE, CURRENT_COST_ESTIMATE,
    RESPONSIBLE_PERSON_OWNER, RESPONSIBLE_PERSON,
    # Mechanism linkage
    MECH_HANDLER_ID, MECH_ACTIVITY_LOCATION, MECH_AGENCY, MECH_SEQ,
    MECH_DETAIL_SEQ,
    # Mechanism
    MECH_TYPE_OWNER, MECH_TYPE, PROVIDER, PROVIDER_CONTACT_NAME,
    PROVIDER_CONTACT_PHONE, PROVIDER_CONTACT_EMAIL,
    # Mechanism detail
    FACE_VALUE_AMOUNT, FACILITY_FACE_VALUE_AMOUNT, EFFECTIVE_DATE,
    EXPIRATION_DATE, ALTERNATIVE, CURRENT_MECHANISM_DETAIL
  )

write_csv(master, out_file, na = "")
