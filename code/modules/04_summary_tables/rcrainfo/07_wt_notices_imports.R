# =============================================================================
# FILE:     07_wt_notices_imports.R
# PURPOSE:  Build the WIETS imports module summary workbook from the raw
#           WT_NOTICES_IMPORTS table, using the shared engine.
# INPUTS:   data/rcrainfo/wt/WT_NOTICES_IMPORTS.csv; sources 00_function.R
# OUTPUTS:  output/summary_tables/WIETS Imports Module Summary Tables.xlsx
# AUTHOR:   Jason Ye
# CREATED:  2026-07-07
# UPDATED:  2026-07-07
# =============================================================================

# "WIETS Imports Module Summary Tables.xlsx" from the raw WT_NOTICES_IMPORTS
# table (Waste Import Export Tracking System; import notices - one row per
# import-notice consent / waste stream), via the shared engine (00_function.R).
# Mirror of the exports config, but the U.S. facility is the IMPORTER and the
# foreign / origin party is the EXPORTER.
#
# WIETS has no code lookup files, so acronym categories (Basel recovery/disposal
# operations, waste-stream type, UN hazard class) are decoded with small
# embedded Title-Case dictionaries. No binary-indicator variables -> two tabs
# (Categorical, Quantitative).
#
# Reads data/rcrainfo/wt/WT_NOTICES_IMPORTS.csv; writes
# output/summary_tables/WIETS Imports Module Summary Tables.xlsx.
# Requires: tidyverse, lubridate, openxlsx2. Run from the repo root.

source("code/modules/04_summary_tables/rcrainfo/00_function.R")

wt_file  <- "data/rcrainfo/wt/WT_NOTICES_IMPORTS.csv"
out_file <- "output/summary_tables/WIETS Imports Module Summary Tables.xlsx"

wt <- read_csv(wt_file, col_types = cols(.default = col_character())) |>
  rename_with(~ str_replace_all(.x, " ", "_"))
all_cols <- names(wt)

# ---- Embedded code dictionaries (no WIETS lookup tables ship with the data) --
# Basel Annex IV recovery (R) / disposal (D) operation codes
lab_basel_ops <- c(
  D3 = "Deep Injection",                D5 = "Specially Engineered Landfill",
  D8 = "Biological Treatment",          D9 = "Physico-Chemical Treatment",
  D10 = "Incineration On Land",         D13 = "Blending Prior To Disposal",
  D14 = "Repackaging Prior To Disposal", D15 = "Storage Pending Disposal",
  R1 = "Use As A Fuel",                 R2 = "Solvent Reclamation/Regeneration",
  R3 = "Recycling Of Organic Substances", R4 = "Recycling/Reclamation Of Metals",
  R5 = "Recycling Of Other Inorganic Materials", R9 = "Used Oil Re-Refining",
  R13 = "Storage Pending Recovery")
lab_waste_type <- c(
  HAZ = "Hazardous Waste", SLABS = "Spent Lead-Acid Batteries",
  UNIV = "Universal Waste", PCB = "PCB Waste", MIXED = "Mixed Waste",
  OIL = "Used Oil", CRT = "Cathode Ray Tubes")
lab_hazard <- c(
  `1` = "Explosives", `2.1` = "Flammable Gas", `2.2` = "Non-Flammable Gas",
  `2.3` = "Toxic Gas", `3` = "Flammable Liquid", `4.1` = "Flammable Solid",
  `4.2` = "Spontaneously Combustible", `4.3` = "Dangerous When Wet",
  `5.1` = "Oxidizer", `5.2` = "Organic Peroxide", `6.1` = "Toxic",
  `6.2` = "Infectious", `7` = "Radioactive", `8` = "Corrosive",
  `9` = "Miscellaneous Dangerous Goods")

# ---- Spec -------------------------------------------------------------------
cat_spec <- list(
  list(col = "NOTICE_STATUS", name = "NOTICE_STATUS", labels = NULL,
       desc = "Current status of the import notice."),
  list(col = "DETERMINATION", name = "DETERMINATION", labels = NULL,
       desc = "EPA consent determination on the notice."),
  list(col = "EXPORTER_COUNTRY", name = "EXPORTER_COUNTRY", labels = NULL,
       desc = "Country of the exporter (origin)."),
  list(col = "FINAL_COUNTRY", name = "FINAL_COUNTRY", labels = NULL,
       desc = "Country of the final recovery / disposal facility."),
  list(col = "FINAL_OPERATIONS", name = "FINAL_OPERATIONS", labels = lab_basel_ops,
       desc = "Basel recovery (R) or disposal (D) operation at the final facility."),
  list(col = "WS_WASTE_TYPE", name = "WS_WASTE_TYPE", labels = lab_waste_type,
       desc = "Waste-stream type."),
  list(col = "HAZARD_CLASS", name = "HAZARD_CLASS", labels = lab_hazard,
       desc = "UN / DOT hazard class of the waste."),
  list(col = "CONSENT_FREQUENCY", name = "CONSENT_FREQUENCY", labels = NULL,
       desc = "Frequency of consented shipments.")
)
quant_dates <- c("LAST_UPDATED_DATE", "DETERMINATION_ISSUED_DATE",
                 "CONSENT_START_DATE", "CONSENT_END_DATE")
quant_nums  <- c(CONSENT_QUANTITY = 2L, CONSENT_SHIPMENTS = 0L)
# no binary-indicator variables in WT_NOTICES_IMPORTS

build_module_summary(
  data = wt, all_cols = all_cols, out_file = out_file, id_col = "IMPORTER_EPA_ID",
  temporal_col = "DETERMINATION_ISSUED_DATE",
  banner = "Identifier: IMPORTER_EPA_ID, one row per import-notice consent / waste stream.",
  cat_spec = cat_spec, quant_dates = quant_dates, quant_nums = quant_nums,
  module_desc = "WIETS (Waste Import Export Tracking System) Imports - notices for bringing hazardous waste into the U.S.
Distinct facilities are U.S. importers."
)
