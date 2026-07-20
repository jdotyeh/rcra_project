# =============================================================================
# FILE:     06_wt_notices_exports.R
# PURPOSE:  Build the WIETS exports module summary workbook from the
#           WT_EXPORTS_MASTER master file, using the shared engine.
# INPUTS:   output/modular_master_files/WT_EXPORTS_MASTER.csv;
#           sources 00_function.R
# OUTPUTS:  output/summary_tables/WIETS Exports Module Summary Tables.xlsx
# AUTHOR:   Jason Ye
# CREATED:  2026-07-07
# UPDATED:  2026-07-19
# =============================================================================

# "WIETS Exports Module Summary Tables.xlsx" from WT_EXPORTS_MASTER, the WIETS
# exports master file (one row per export-notice waste stream x annual-report
# year), via the shared engine (00_function.R), so the workbook is in the same
# house format.
#
# The spec covers every column of the master that carries a coded, dated, or
# numeric value, including the country and Basel operation of each party on the
# shipment chain (importer, shipper, interim facility, final facility) and the
# waste-stream codes. What is left out is the notice and consent numbers, every
# party's name, address, and EPA or foreign identifier, and the free-text waste
# description.
#
# WIETS has no code lookup files, so acronym categories (Basel recovery/disposal
# operations, waste-stream type, UN hazard class) are decoded with small
# embedded Title-Case dictionaries. The master adds the annual-report actuals
# (REPORT_YEAR, QUANTITY_ACTUAL, QUANTITY_UOM, SHIPMENTS_ACTUAL) on top of the
# notice. No binary-indicator variables -> two tabs (Categorical, Quantitative).
#
# Reads output/modular_master_files/WT_EXPORTS_MASTER.csv; writes
# output/summary_tables/WIETS Exports Module Summary Tables.xlsx.
# Requires: tidyverse, lubridate, openxlsx2. Run from the repo root.

source("code/modules/04_summary_tables/rcrainfo/00_function.R")

wt_file  <- "output/modular_master_files/WT_EXPORTS_MASTER.csv"
out_file <- "output/summary_tables/WIETS Exports Module Summary Tables.xlsx"

wt <- read_csv(wt_file, col_types = cols(.default = col_character()))
all_cols <- names(wt)

# ---- Embedded code dictionaries (no WIETS lookup tables ship with the data) --
# Basel Annex IV recovery (R) / disposal (D) operation codes
lab_basel_ops <- c(
  D3 = "Deep Injection",               D5 = "Specially Engineered Landfill",
  D8 = "Biological Treatment",         D9 = "Physico-Chemical Treatment",
  D10 = "Incineration On Land",        D12 = "Permanent Storage",
  D13 = "Blending Prior To Disposal",
  D14 = "Repackaging Prior To Disposal", D15 = "Storage Pending Disposal",
  R1 = "Use As A Fuel",                R2 = "Solvent Reclamation/Regeneration",
  R3 = "Recycling Of Organic Substances", R4 = "Recycling/Reclamation Of Metals",
  R5 = "Recycling Of Other Inorganic Materials", R9 = "Used Oil Re-Refining",
  R12 = "Exchange For Recovery",       R13 = "Storage Pending Recovery")
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
  list(col = "NOTICE_TYPE", name = "NOTICE_TYPE", labels = NULL,
       desc = "Direction of the notice; every row of this master is an export."),
  list(col = "NOTICE_PROGRESS", name = "NOTICE_PROGRESS", labels = NULL,
       desc = "How far the notice has moved through EPA's review."),
  list(col = "NOTICE_STATUS", name = "NOTICE_STATUS", labels = NULL,
       desc = "Current status of the export notice."),
  list(col = "DETERMINATION", name = "DETERMINATION", labels = NULL,
       desc = "EPA consent determination on the notice."),
  list(col = "CONSENT_UOM", name = "CONSENT_UOM", labels = NULL,
       desc = "Unit of measure the consented quantity is stated in."),
  list(col = "CONSENT_FREQUENCY", name = "CONSENT_FREQUENCY", labels = NULL,
       desc = "Frequency of consented shipments."),
  list(col = "IMPORTER_COUNTRY", name = "IMPORTER_COUNTRY", labels = NULL,
       desc = "Country of the importer (destination)."),
  list(col = "SHIPPER_COUNTRY", name = "SHIPPER_COUNTRY", labels = NULL,
       desc = "Country of the shipper that sends the waste."),
  list(col = "INTERIM_COUNTRY", name = "INTERIM_COUNTRY", labels = NULL,
       desc = "Country of the interim facility, where the shipment passes through one."),
  list(col = "INTERIM_OPERATIONS", name = "INTERIM_OPERATIONS", labels = lab_basel_ops,
       desc = "Basel recovery (R) or disposal (D) operation at the interim facility."),
  list(col = "FINAL_COUNTRY", name = "FINAL_COUNTRY", labels = NULL,
       desc = "Country of the final recovery / disposal facility."),
  list(col = "FINAL_OPERATIONS", name = "FINAL_OPERATIONS", labels = lab_basel_ops,
       desc = "Basel recovery (R) or disposal (D) operation at the final facility."),
  list(col = "WS_WASTE_TYPE", name = "WS_WASTE_TYPE", labels = lab_waste_type,
       desc = "Waste-stream type."),
  list(col = "HAZARD_CLASS", name = "HAZARD_CLASS", labels = lab_hazard,
       desc = "UN / DOT hazard class of the waste."),
  list(col = "UN_ID_NUMBER", name = "UN_ID_NUMBER", labels = NULL,
       desc = "UN number identifying the substance for transport."),
  list(col = "BASEL_WASTE_CODES", name = "BASEL_WASTE_CODES", labels = NULL,
       desc = "Basel Convention waste codes on the stream (one row can list several)."),
  list(col = "EPA_WASTE_CODES", name = "EPA_WASTE_CODES", labels = NULL,
       desc = "RCRA waste codes on the stream (one row can list several)."),
  list(col = "REPORT_YEAR", name = "REPORT_YEAR", labels = NULL,
       desc = "Annual-report year the row's actual quantities come from."),
  list(col = "QUANTITY_UOM", name = "QUANTITY_UOM", labels = NULL,
       desc = "Unit of measure the reported actual quantity is stated in.")
)
quant_dates <- c("LAST_UPDATED_DATE", "DETERMINATION_ISSUED_DATE",
                 "CONSENT_START_DATE", "CONSENT_END_DATE")
quant_nums  <- c(WASTE_STREAM_NUMBER = 0L,
                 CONSENT_QUANTITY = 2L, CONSENT_SHIPMENTS = 0L,
                 QUANTITY_ACTUAL = 2L, SHIPMENTS_ACTUAL = 0L)
# no binary-indicator variables in WT_EXPORTS_MASTER

build_module_summary(
  data = wt, all_cols = all_cols, out_file = out_file, id_col = "EXPORTER_EPA_ID",
  temporal_col = "DETERMINATION_ISSUED_DATE",
  banner = "Identifier: EXPORTER_EPA_ID, one row per export-notice waste stream x annual-report year.",
  cat_spec = cat_spec, quant_dates = quant_dates, quant_nums = quant_nums,
  module_desc = "WIETS (Waste Import Export Tracking System) Exports - notices for shipping hazardous waste out of the U.S.
  Distinct facilities are U.S. exporters. Summarized from the WT_EXPORTS_MASTER master file.",
  missing_notes = list(
    categorical = c(
      "CONSENT_UOM / CONSENT_FREQUENCY: Not applicable. Blank for notices that were objected to or withdrawn rather than consented.",
      "INTERIM_COUNTRY / INTERIM_OPERATIONS: Not applicable. Most shipments go straight to the final facility.",
      "REPORT_YEAR / QUANTITY_UOM: Not applicable. Blank for consents never reported in an annual report.",
      "BASEL_WASTE_CODES / EPA_WASTE_CODES: One waste stream can carry several codes, and the column holds them as one semicolon-separated string. Each distinct string counts as one category here, and a string longer than 60 characters is shown with its middle elided, so two long lists that differ only in the elided part appear as separate rows that read alike."),
    quantitative = c(
      "CONSENT_START_DATE, CONSENT_END_DATE, CONSENT_QUANTITY, CONSENT_SHIPMENTS,: Not applicable. Blank for notices that were objected to or withdrawn rather than consented.",
      "QUANTITY_ACTUAL / SHIPMENTS_ACTUAL: Not applicable. Blank for consents never reported in an annual report."))
)
