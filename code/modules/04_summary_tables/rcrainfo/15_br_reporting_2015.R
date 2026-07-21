# =============================================================================
# FILE:     15_br_reporting_2015.R
# PURPOSE:  Build the Biennial Report 2015 cycle summary workbook from the raw
#           BR_REPORTING_2015 table, using the shared engine.
# INPUTS:   data/rcrainfo/br/BR_REPORTING_2015.csv,
#           data/rcrainfo/hd/HD_LU_NAICS.csv; sources 00_function.R
# OUTPUTS:  output/summary_tables/Biennial Report 2015 Summary Tables.xlsx
# AUTHOR:   Jason Ye
# CREATED:  2026-07-07
# UPDATED:  2026-07-07
# =============================================================================

# "Biennial Report 2015 Summary Tables.xlsx" from the raw BR_REPORTING_2015
# table (one row per waste form / management line), via the shared engine
# (00_function.R). One script per report cycle (kept as separate files per
# request) with the same spec; the per-cycle glossary notes differ.
#
# Reads data/rcrainfo/br/BR_REPORTING_2015.csv (+ BR lookup tables and
# data/rcrainfo/hd/HD_LU_NAICS.csv for labels); writes
# output/summary_tables/Biennial Report 2015 Summary Tables.xlsx.
# Requires: tidyverse, lubridate, openxlsx2. Run from the repo root.

# Load the shared summary-tables engine (loads tidyverse / lubridate / openxlsx2).
source("code/modules/04_summary_tables/rcrainfo/00_function.R")

br_root  <- "data/rcrainfo/br"
year     <- 2015L
out_file <- "output/summary_tables/Biennial Report 2015 Summary Tables.xlsx"

# ---- Label dictionaries -----------------------------------------------------
lu_labels <- function(path, code, desc, trunc = 45) {
  read_csv(path, col_types = cols(.default = col_character())) |>
    rename_with(~ str_replace_all(.x, " ", "_")) |>
    filter(OWNER == "HQ", !is.na(.data[[desc]]), .data[[desc]] != "") |>
    distinct(.data[[code]], .keep_all = TRUE) |>
    transmute(code = .data[[code]], lab = str_trunc(prettify(.data[[desc]]), trunc)) |>
    deframe()
}
lab_source <- lu_labels(file.path(br_root, "BR_LU_SOURCE_CODE.csv"),       "SOURCE_CODE",       "SOURCE_CODE_NAME")
lab_form   <- lu_labels(file.path(br_root, "BR_LU_FORM_CODE.csv"),         "FORM_CODE",         "FORM_CODE_NAME")
lab_mgmt   <- lu_labels(file.path(br_root, "BR_LU_MANAGEMENT_METHOD.csv"), "MANAGEMENT_METHOD", "MANAGEMENT_METHOD_DESC")
lab_brform <- c(GM = "Generation and Management Form", WR = "Waste Received Form", XX = "Site Identification Form Only")
lab_region <- setNames(paste("EPA Region", 1:10), sprintf("%02d", 1:10))
# NAICS: universal lookup (HD_LU_NAICS); keep the most recent NAICS cycle per code
lab_naics  <- read_csv("data/rcrainfo/hd/HD_LU_NAICS.csv",
                       col_types = cols(.default = col_character())) |>
  rename_with(~ str_replace_all(.x, " ", "_")) |>
  filter(OWNER == "HQ", !is.na(NAICS_DESC), NAICS_DESC != "") |>
  arrange(desc(NAICS_CYCLE)) |> distinct(NAICS_CODE, .keep_all = TRUE) |>
  transmute(NAICS_CODE, lab = str_trunc(prettify(NAICS_DESC), 70)) |> deframe()

# ---- Spec -------------------------------------------------------------------
id_col <- "HANDLER_ID"
cat_spec <- list(
  list(col = "ACTIVITY_LOCATION", name = "ACTIVITY_LOCATION", labels = NULL,
       desc = "State or territory whose implementing agency is responsible for the report."),
  list(col = "REGION", name = "REGION", labels = lab_region,
       desc = "EPA region in which the site is located."),
  list(col = "BR_FORM", name = "BR_FORM", labels = lab_brform,
       desc = "Biennial Report form the line was reported on."),
  list(col = "PRIMARY_NAICS", name = "PRIMARY_NAICS", labels = lab_naics,
       desc = "Primary NAICS industry classification of the site."),
  list(col = "SOURCE_CODE", name = "SOURCE_CODE", labels = lab_source,
       desc = "Process or activity that generated the waste."),
  list(col = "FORM_CODE", name = "FORM_CODE", labels = lab_form,
       desc = "Physical form / general category of the waste."),
  list(col = "MANAGEMENT_METHOD", name = "MANAGEMENT_METHOD", labels = lab_mgmt,
       desc = "Method used to treat, dispose of, or recycle the waste."),
  list(col = "MANAGEMENT_CATEGORY", name = "MANAGEMENT_CATEGORY", labels = NULL,
       desc = "Broad category of waste management.")
)
quant_dates <- c("LAST_CHANGE")
quant_nums  <- c(GENERATION_TONS = 2L, MANAGED_TONS = 2L,
                 SHIPPED_TONS = 2L, RECEIVED_TONS = 2L)
flag_simple <- c("GEN_ID_INCLUDED_IN_NBR", "GEN_WASTE_INCLUDED_IN_NBR",
                 "MGMT_ID_INCLUDED_IN_NBR", "MGMT_WASTE_INCLUDED_IN_NBR",
                 "SHIP_ID_INCLUDED_IN_NBR", "SHIP_WASTE_INCLUDED_IN_NBR",
                 "RECV_ID_INCLUDED_IN_NBR", "RECV_WASTE_INCLUDED_IN_NBR",
                 "FEDERAL_WASTE", "WASTEWATER", "PRIORITY_CHEMICAL")

# ---- Load + build -----------------------------------------------------------
# Derive the column subset actually needed from the spec.
need  <- needed_columns(cat_spec, quant_dates, quant_nums, flag_simple, id_col = id_col)
# Cycle-specific BR_REPORTING file path.
br_file <- file.path(br_root, sprintf("BR_REPORTING_%d.csv", year))
# Header list, normalized to underscores so all_cols matches the engine spec column names.
all_cols <- read_csv(br_file, n_max = 0, show_col_types = FALSE) |>
  names() |> str_replace_all(" ", "_")
# The raw BR_REPORTING file ships column names with spaces; select on the
# space-form and rename to underscores so the spec matches.
br <- read_csv(br_file, col_select = all_of(str_replace_all(need, "_", " ")),
               col_types = cols(.default = col_character())) |>
  rename_with(~ str_replace_all(.x, " ", "_"))

# Run the engine to compute the summaries and write the workbook.
build_module_summary(
  data = br, all_cols = all_cols, out_file = out_file, id_col = id_col,
  temporal_col = "LAST_CHANGE",
  banner = sprintf("Identifier: HANDLER_ID  (%d Biennial Report; 1 row per waste form / management line)", year),
  cat_spec = cat_spec, quant_dates = quant_dates, quant_nums = quant_nums,
  flag_simple = flag_simple,
  module_desc = "Biennial Report 2015 - the hazardous-waste report that LQGs and TSDFs file every two years.",
  missing_notes = list(
    categorical = c(
      "SOURCE_CODE: Not applicable. Recorded only on generation lines (BR_FORM = GM); blank on waste-received lines (BR_FORM = WR).",
      "MANAGEMENT_CATEGORY: Not determinable.",
      "Source code glossary:
G11: Discarding off-specification, out-of-date, and/or unused chemicals or products.
G61: Received from off-site for storage/bulking and transfer off-site for treatment or disposal.
G22: Laboratory analytical wastes (used chemicals from laboratory operations).
G09: Other production or service-related processes from which the waste is a direct outflow or result.
G19: Other one-time or intermittent processes.",
      "Form code glossary:
W001: Lab packs from any source not containing acute hazardous waste.
W219: Other organic liquid.
W801: Compressed gases.
W005: Waste pharmaceuticals managed as hazardous waste.
W203: Concentrated non-halogenated (e.g., non-chlorinated) solvent.",
      "Management method glossary:
H141: Storage and Transfer - The site receiving this waste stored/bulked and transferred the waste with no reclamation, recovery, destruction, treatment, or disposal at that site.
H040: Incineration; thermal destruction other than use as a fuel.
H061: Fuel blending prior to energy recovery at another site (waste generated on-site or received from off-site).
H020: Solvents recovery.
H110: Stabilization prior to land disposal at another site (encapsulation/stabilization/fixation).",
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
EPA Region 10: Alaska, Idaho, Oregon, Washington"))
)
