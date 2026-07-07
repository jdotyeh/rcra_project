# "Financial Assurance Module Summary Tables.xlsx" from the raw FA_COST_ESTIMATE
# table (the Financial Assurance module's central cost-estimate record: one row
# per handler x FA-type x coverage), via the shared engine (00_engine.R), so
# the workbook is in the same house format as the other modules.
#
# FA is normalized into several tables (mechanisms, cost estimates, details);
# FA_COST_ESTIMATE is the richest single table - it carries categorical, numeric,
# date, and a Y/N flag, so it yields all three tabs.
#
# Reads data/rcrainfo/fa/FA_COST_ESTIMATE.csv (+ FA lookup tables for labels);
# writes output/summary_tables/Financial Assurance Module Summary Tables.xlsx.
# Requires: tidyverse, lubridate, openxlsx2. Run from the repo root.

source("code/modules/02_summary_tables/rcrainfo/00_engine.R")

fa_dir   <- "data/rcrainfo/fa"
out_file <- "output/summary_tables/Financial Assurance Module Summary Tables.xlsx"

# ---- Load (small single-file table) -----------------------------------------
fa <- read_csv(file.path(fa_dir, "FA_COST_ESTIMATE.csv"),
               col_types = cols(.default = col_character())) |>
  rename_with(~ str_replace_all(.x, " ", "_"))
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

# ---- Decode FA-type and cost-estimate-reason acronyms from module lookups ----
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

# ---- Spec -------------------------------------------------------------------
cat_spec <- list(
  list(col = "COST_FA_TYPE", name = "COST_FA_TYPE", labels = lab_fa_type,
       desc = "Financial-assurance obligation the cost estimate covers."),
  list(col = "COST_AGENCY", name = "COST_AGENCY", labels = agency_labels,
       desc = "Agency responsible for the cost estimate."),
  list(col = "COST_ACTIVITY_LOCATION", name = "COST_ACTIVITY_LOCATION", labels = NULL,
       desc = "State or territory whose implementing agency is responsible for the cost estimate."),
  list(col = "RESPONSIBLE_PERSON_OWNER", name = "RESPONSIBLE_PERSON_OWNER", labels = owner_labels,
       desc = "Organization that owns the responsible-person record."),
  list(col = "COST_ESTIMATE_REASON", name = "COST_ESTIMATE_REASON", labels = lab_reason,
       desc = "Reason the cost estimate was submitted or updated.")
)
quant_dates <- c("COST_ESTIMATE_DATE", "UPDATE_DUE_DATE")
quant_nums  <- c(COST_ESTIMATE_AMOUNT = 2L)
flag_simple <- c("CURRENT_COST_ESTIMATE")

build_module_summary(
  gsheet_id = "1n5yga4GJ6aslC82dIMPxrXu8fSwVceTbKX7-w6LgGmg",
  data = fa, all_cols = all_cols, out_file = out_file, id_col = "HANDLER_ID",
  temporal_col = "COST_ESTIMATE_DATE",
  banner = "Identifier: HANDLER_ID, one row per cost-estimate coverage.",
  cat_spec = cat_spec, quant_dates = quant_dates, quant_nums = quant_nums,
  flag_simple = flag_simple,
  module_desc = "Financial Assurance - cost estimates for closure, post-closure, and cleanup that facilities must be able to pay for; held mainly by permitted TSDF.",
  missing_notes = list(
    categorical = c(
      "RESPONSIBLE_PERSON_OWNER: Missing. Incomplete reporting."),
    quantitative = c(
      "UPDATE_DUE_DATE: Not determinable."))
)
