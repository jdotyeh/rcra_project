# =============================================================================
# FILE:     01_hd_reporting.R
# PURPOSE:  Build the Handler module summary workbook from the raw HD_REPORTING
#           table, using the shared engine.
# INPUTS:   data/rcrainfo/hd/HD_REPORTING.csv; sources 00_function.R
# OUTPUTS:  output/summary_tables/Handler Module Summary Tables.xlsx
# AUTHOR:   Jason Ye
# CREATED:  2026-07-07
# UPDATED:  2026-07-07
# =============================================================================

# "Handler Module Summary Tables.xlsx" from the raw HD_REPORTING table, via
# the shared engine (00_function.R). Defines the Handler module's spec (which
# columns are Categorical / Quantitative / Dummy + value labels) and calls
# build_module_summary().
#
# Reads data/rcrainfo/hd/HD_REPORTING.csv; writes
# output/summary_tables/Handler Module Summary Tables.xlsx.
# Requires: tidyverse, lubridate, openxlsx2. Run from the repo root.

source("code/modules/04_summary_tables/rcrainfo/00_function.R")

hd_file  <- "data/rcrainfo/hd/HD_REPORTING.csv"
out_file <- "output/summary_tables/Handler Module Summary Tables.xlsx"

# ---- Value-label dictionaries (embedded; only the raw file is needed) -------
lab_source <- c(I = "Implementer", N = "Notification",
                B = "Annual/Biennial Report\nUpdate with Notification",
                D = "Deactivation", `T` = "Temporary")
lab_fedgen <- c(`1` = "Large Quantity Generator", `2` = "Small Quantity Generator",
                `3` = "Very Small Quantity Generator", N = "Not a Generator")
lab_land   <- c(P = "Private", C = "County", D = "District", F = "Federal",
                I = "Indian/Tribal", M = "Municipal", S = "State", O = "Other")
# NOTE: the original sheet printed NAICS code "56921" (invalid); the data value
# is 56291 (Remediation Services), used here.
lab_naics  <- c(`56299`  = "All Other Waste Management Services",
                `811111` = "General Automotive Repair",
                `811121` = "Automotive Body, Paint, and Interior Repair and Maintenance",
                `56291`  = "Remediation Services",
                `44711`  = "Gasoline Stations with Convenience Stores")
lab_genstatus <- c(N = "Not a Generator",
                   LQG = "Large Quantity Generator",
                   SQG = "Small Quantity Generator",
                   VSG = "Very Small Quantity Generator")

# ---- Spec -------------------------------------------------------------------
id_col <- "HANDLER_ID"
cat_spec <- list(
  list(col = "REGION", name = "REGION", labels = NULL,
       desc = "EPA region in which the site is located."),
  list(col = "ACTIVITY_LOCATION", name = "ACTIVITY_LOCATION", labels = NULL,
       desc = "The state or territory whose implementing agency is responsible for the site."),
  list(col = "SOURCE_TYPE", name = "SOURCE_TYPE", labels = lab_source,
       desc = "Type of source document providing the current record."),
  list(col = "FED_WASTE_GENERATOR", name = "FED_WASTE_GENERATOR", labels = lab_fedgen,
       desc = "Generator status of the site according to Federal regulations."),
  list(col = "GENSTATUS", name = "GENSTATUS", labels = lab_genstatus,
       desc = "Overall current generator status of the site."),
  list(col = "LAND_TYPE", name = "LAND_TYPE", labels = lab_land,
       desc = "Ownership type of the land on which the site is located."),
  list(col = "NAIC1", name = "NAICS1", labels = lab_naics,
       desc = "Primary NAICS industry classification of the site."),
  list(col = "ACTIVE_SITE", name = "ACTIVE_SITE", labels = NULL, active = TRUE,
       desc = "H = Handler Activities
P = Permitting Activities
A = Corrective Action Activities
C = Converter
S = State-Specific Activities
- = Not in the Universe")
)
quant_dates    <- c("RECEIVE_DATE", "HHANDLER_LAST_CHANGE")
quant_nums     <- c(REPORT_CYCLE = 0L, LOCATION_LATITUDE = 2L, LOCATION_LONGITUDE = 2L)
flag_simple    <- c("SHORT_TERM_GENERATOR", "IMPORTER", "MIXED_WASTE_GENERATOR",
                    "TRANSPORTER", "RECYCLER", "UNDERGROUND_INJECTION",
                    "OFF_SITE_RECEIPT", "UNIVWASTE", "COMMERCIAL_TSD", "SUBJCA", "SNC")
flag_composite <- c(USED_OIL = "Y", AS_FEDERALLY_REGULATED_TSDF = "[^-]",
                    OPERATING_TSDF = "[^-]", FA_REQUIRED = "[^-]")

# ---- Load (only the needed columns) -----------------------------------------
need <- needed_columns(cat_spec, quant_dates, quant_nums, flag_simple, flag_composite, id_col = id_col)
all_cols <- read_csv(hd_file, n_max = 0, show_col_types = FALSE) |>
  names() |> str_replace_all(" ", "_")
hd <- read_csv(hd_file, col_select = all_of(str_replace_all(need, "_", " ")),
               col_types = cols(.default = col_character())) |>
  rename_with(~ str_replace_all(.x, " ", "_"))

build_module_summary(
  data = hd, all_cols = all_cols, out_file = out_file, id_col = id_col,
  temporal_col = "RECEIVE_DATE", banner = "Identifier: HANDLER_ID, one row per site.",
  cat_spec = cat_spec, quant_dates = quant_dates, quant_nums = quant_nums,
  flag_simple = flag_simple, flag_composite = flag_composite,
  module_desc = "Handlers - generators + transporters + TSDFs (treatment, storage, or disposal facilities).",
  missing_notes = list(
    categorical = c(
      "LAND_TYPE: Missing. Incomplete reporting.",
      "NAICS1: Missing. Incomplete reporting.",
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
      "LOCATION_LATITUDE/LOCATION_LONGITUDE: Missing. Not reported.",
      "REPORT_CYCLE: Not applicable. Biennial Reports only collect data from LQGs."
    )
  )
)
