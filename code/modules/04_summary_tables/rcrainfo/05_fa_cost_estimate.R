# =============================================================================
# FILE:     05_fa_cost_estimate.R
# PURPOSE:  Build the Financial Assurance module summary workbook from the
#           FA_MASTER master file, using the shared engine.
# INPUTS:   output/modular_master_files/FA_MASTER.csv (+ data/rcrainfo/fa/
#           lookup tables for labels); sources 00_function.R
# OUTPUTS:  output/summary_tables/Financial Assurance Module Summary Tables.xlsx
# AUTHOR:   Jason Ye
# CREATED:  2026-07-07
# UPDATED:  2026-07-19
# =============================================================================

# "Financial Assurance Module Summary Tables.xlsx" from FA_MASTER, the
# Financial Assurance master file (one row per cost estimate x mechanism
# detail), via the shared engine (00_function.R), so the workbook is in the
# same house format as the other modules.
#
# The master joins the cost estimates to the mechanisms that fund them, so the
# workbook covers both sides: the estimate's type, agency, sequence, amount,
# and dates, and the mechanism's agency, type, sequence, face values, and
# coverage window. The two current-record flags arrive coded 1/0.
#
# The spec covers every column of the master that carries a coded, dated,
# numeric, or indicator value. What is left out is the facility identifier
# repeated on the mechanism rows, the staff identifier, and the provider's
# name and contact details.
#
# Reads output/modular_master_files/FA_MASTER.csv (+ FA lookup tables for
# labels); writes output/summary_tables/Financial Assurance Module Summary
# Tables.xlsx.
# Requires: tidyverse, lubridate, openxlsx2. Run from the repo root.

# Load the shared summary-tables engine (loads tidyverse / lubridate / openxlsx2).
source("code/modules/04_summary_tables/rcrainfo/00_function.R")

fa_file  <- "output/modular_master_files/FA_MASTER.csv"
fa_dir   <- "data/rcrainfo/fa"
out_file <- "output/summary_tables/Financial Assurance Module Summary Tables.xlsx"

# ---- Load (small single-file master) ----------------------------------------
# Read the master as character to preserve zero-padded codes.
fa <- read_csv(fa_file, col_types = cols(.default = col_character()))
# Full header list; the engine reports any columns not covered by the spec.
all_cols <- names(fa)

# ---- Common code labels (provided) ------------------------------------------
agency_labels <- c(E = "EPA", S = "State",
                   J = "Joint with State Lead", P = "Joint with EPA Lead")
owner_labels  <- c(HQ = "Nationally Defined Values",
                   `01` = "EPA Region 1", `02` = "EPA Region 2", `03` = "EPA Region 3",
                   `04` = "EPA Region 4", `05` = "EPA Region 5", `06` = "EPA Region 6",
                   `07` = "EPA Region 7", `08` = "EPA Region 8", `09` = "EPA Region 9",
                   `10` = "EPA Region 10",
                   `1` = "EPA Region 1", `2` = "EPA Region 2", `3` = "EPA Region 3",
                   `4` = "EPA Region 4", `5` = "EPA Region 5", `6` = "EPA Region 6",
                   `7` = "EPA Region 7", `8` = "EPA Region 8", `9` = "EPA Region 9")

# ---- Decode FA-type, reason, and mechanism acronyms from module lookups -----
lu_to_labels <- function(file, code, desc, trunc = 45) {
  read_csv(file.path(fa_dir, file), col_types = cols(.default = col_character())) |>
    rename_with(~ str_replace_all(.x, " ", "_")) |>
    filter(OWNER == "HQ", !is.na(.data[[desc]]), .data[[desc]] != "") |>
    distinct(.data[[code]], .keep_all = TRUE) |>
    transmute(code = .data[[code]], lab = str_trunc(prettify(.data[[desc]]), trunc)) |>
    deframe()
}
lab_fa_type <- lu_to_labels("FA_LU_FA_TYPE.csv", "FA_TYPE", "FA_TYPE_DESC")
lab_reason  <- lu_to_labels("FA_LU_COST_ESTIMATE_REASON.csv",
                            "COST_ESTIMATE_REASON", "COST_ESTIMATE_REASON_DESC")
lab_mech    <- lu_to_labels("FA_LU_MECHANISM_TYPE.csv",
                            "MECHANISM_TYPE", "MECHANISM_DESC")

# ---- Spec -------------------------------------------------------------------
cat_spec <- list(
  list(col = "COST_ACTIVITY_LOCATION", name = "COST_ACTIVITY_LOCATION", labels = NULL,
       desc = "State or territory whose implementing agency is responsible for the cost estimate."),
  list(col = "COST_FA_TYPE", name = "COST_FA_TYPE", labels = lab_fa_type,
       desc = "Financial-assurance obligation the cost estimate covers."),
  list(col = "COST_AGENCY", name = "COST_AGENCY", labels = agency_labels,
       desc = "Agency responsible for the cost estimate."),
  list(col = "COST_ESTIMATE_REASON", name = "COST_ESTIMATE_REASON", labels = lab_reason,
       desc = "Reason the cost estimate was submitted or updated."),
  list(col = "RESPONSIBLE_PERSON_OWNER", name = "RESPONSIBLE_PERSON_OWNER", labels = owner_labels,
       desc = "Organization that owns the responsible-person record."),
  list(col = "MECH_ACTIVITY_LOCATION", name = "MECH_ACTIVITY_LOCATION", labels = NULL,
       desc = "State or territory whose implementing agency is responsible for the mechanism."),
  list(col = "MECH_AGENCY", name = "MECH_AGENCY", labels = agency_labels,
       desc = "Agency responsible for the financial mechanism."),
  list(col = "MECH_TYPE_OWNER", name = "MECH_TYPE_OWNER", labels = owner_labels,
       desc = "Organization that defines the mechanism-type code list."),
  list(col = "MECH_TYPE", name = "MECH_TYPE", labels = lab_mech,
       desc = "Type of the financial mechanism funding the estimate."),
  list(col = "ALTERNATIVE", name = "ALTERNATIVE", labels = NULL,
       desc = "Marks a mechanism accepted as an alternative to the standard instrument.")
)
quant_dates <- c("COST_ESTIMATE_DATE", "UPDATE_DUE_DATE",
                 "EFFECTIVE_DATE", "EXPIRATION_DATE")
quant_nums  <- c(COST_COVERAGE_SEQ = 0L, COST_ESTIMATE_AMOUNT = 2L,
                 MECH_SEQ = 0L, MECH_DETAIL_SEQ = 0L,
                 FACE_VALUE_AMOUNT = 2L, FACILITY_FACE_VALUE_AMOUNT = 2L)
flag_simple <- c("CURRENT_COST_ESTIMATE", "CURRENT_MECHANISM_DETAIL")

# Run the engine to compute the summaries and write the workbook.
build_module_summary(
  data = fa, all_cols = all_cols, out_file = out_file, id_col = "HANDLER_ID",
  temporal_col = "COST_ESTIMATE_DATE",
  banner = "Identifier: HANDLER_ID, one row per cost estimate x mechanism detail combination.",
  cat_spec = cat_spec, quant_dates = quant_dates, quant_nums = quant_nums,
  flag_simple = flag_simple,
  module_desc = "Financial Assurance - cost estimates for closure, post-closure, and cleanup that facilities must be able to pay for; held mainly by permitted TSDF. Summarized from the FA_MASTER master file.",
  missing_notes = list(
    categorical = c(
      "RESPONSIBLE_PERSON_OWNER: Missing. Incomplete reporting.",
      "MECH_ACTIVITY_LOCATION / MECH_AGENCY / MECH_TYPE_OWNER / MECH_TYPE: Not applicable. Blank on cost estimates with no mechanism on file.",
      "ALTERNATIVE: Not applicable. Set only on the few mechanisms accepted as an alternative instrument."),
    quantitative = c(
      "UPDATE_DUE_DATE: Not determinable.",
      "EFFECTIVE_DATE / EXPIRATION_DATE / MECH_SEQ / MECH_DETAIL_SEQ / FACE_VALUE_AMOUNT / FACILITY_FACE_VALUE_AMOUNT: Not applicable. Blank on cost estimates with no mechanism on file.",
      "FACILITY_FACE_VALUE_AMOUNT: Also blank where the mechanism covers a single facility, so no facility-level split is recorded."),
    dummy = c(
      "CURRENT_MECHANISM_DETAIL: Missing. Blank on cost estimates with no mechanism on file."))
)
