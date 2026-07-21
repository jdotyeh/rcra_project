# =============================================================================
# FILE:     01_panel_2015_2023_balanced.R
# PURPOSE:  Build the balanced facility-cycle panel of LQG and/or TSDF handlers
#           recognized in every Biennial Report cycle 2015-2023, with BR status
#           and tonnage columns, handler attributes, and the FRS link.
# INPUTS:   data/rcrainfo/br/BR_REPORTING_<cycle>.csv,
#           output/modular_master_files/HD_MASTER.csv,
#           data/frs/FRS_PROGRAM_LINKS.csv; sources 00_panel_functions.R
# OUTPUTS:  output/panels/BR_PANEL_2015_2023_BALANCED/BR_PANEL_2015_2023_BALANCED.csv
# AUTHOR:   Jason Ye
# CREATED:  2026-07-10
# UPDATED:  2026-07-16
# =============================================================================
#
# Facility-cycle panel of RCRA handlers recognized in the Biennial Report as
# large quantity generators (LQGs) and/or treatment, storage and disposal
# facilities (TSDFs), report cycles 2015-2023 (odd years only). One
# row per handler x cycle; balanced, so only handlers recognized as LQG and/or
# TSDF in ALL five cycles are kept (5 rows per handler: 2015/2017/2019/2021/2023).
#
# All build logic lives in 00_panel_functions.R (build_br_panel() and its
# helpers); this script sets the panel's parameters and runs it. The unbalanced
# counterpart (02_panel_2015_2023_unbalanced.R) runs the same builder with
# balanced = FALSE.
#
# Columns
#   HANDLER_ID, FRS_ID, REPORT_CYCLE
#   FRS_ID             EPA Facility Registry Service REGISTRY_ID, linked from the
#                      FRS Program Links file on the RCRAInfo Handler ID
#                      (PGM_SYS_ID where PGM_SYS_ACRNM == "RCRAINFO"). One
#                      REGISTRY_ID per Handler ID; NA if no RCRAINFO link exists.
#   BR_GENERATOR       "L" if any BR_REPORTING row that cycle has
#                      CALCULATED_GENERATOR_STATUS == "L", else "N".
#   BR_TSDF            1 if any row that cycle has MGMT_ID_INCLUDED_IN_NBR or
#                      RECV_ID_INCLUDED_IN_NBR == "Y" (raw BR coding), else 0.
#   BR_GENERATE_TONS   Facility-year Biennial Report tonnages, summed over the
#   BR_MANAGE_TONS     BR_REPORTING waste lines, each restricted to the lines
#   BR_SHIP_TONS       EPA counts toward the matching Biennial Report total
#   BR_RECEIVE_TONS    (<x> WASTE INCLUDED IN NBR == "Y"); this keeps the totals
#                      on the panel's Biennial Report basis and avoids double
#                      counting.
#                      Written as clean fixed-decimal strings (<=7 dp).
#   HD_*               Handler-master (HD_MASTER) attributes, one value per
#                      facility-year. The activity indicators arrive from the
#                      master coded 1/0, with "U" where an "N" predates the
#                      flag's existence (see the 02_modular_master_files
#                      README), and keep that coding here. Every source record
#                      sets a value from its RECEIVE_DATE forward (step
#                      function), carrying the last value before Jan 1 in.
#                      Assignment over the calendar year then depends on the
#                      variable class:
#                        - ranked statuses (HD_GENERATOR, HD_TSDF,
#                          HD_STATE_GENERATOR): most days of the year wins, day
#                          ties break on severity (L>S>VS>N>P>U, 1>0>U, federal
#                          hierarchy for the state code);
#                        - 1/0 activity indicators: severity-dominant, 1 at any
#                          point of the year makes the year 1, and a real 0
#                          beats an unknown U;
#                        - plain descriptive attributes (location fields): most
#                          days wins, day ties toward the most recently
#                          received value.
#                      Source column -> panel name:
#                        HD_ACTIVITY_STATE      <- ACTIVITY_LOCATION
#                        HD_LOCATION_STATE      <- LOCATION_STATE
#                        HD_LOCATION_COUNTY     <- COUNTY_CODE
#                        HD_EPA_REGION          <- REGION
#                        HD_LOCATION_LATITUDE   <- LOCATION_LATITUDE
#                        HD_LOCATION_LONGITUDE  <- LOCATION_LONGITUDE
#                        NAICS4, NAICS6_1-4     <- NAICS_CODE (all NAICS_SEQ)
#                        HD_GENERATOR           <- FED_WASTE_GENERATOR (1->L,2->S,3->VS;
#                          independent of BR_GENERATOR, resolved by duration then severity)
#                        HD_STATE_GENERATOR     <- STATE_WASTE_GENERATOR (ranked on the
#                          federal hierarchy L=1>S=2>VS=3>N; non-convertible codes lowest)
#                        HD_SHORT_TERM_GENERATOR<- SHORT_TERM_GENERATOR
#                        HD_TSDF                <- TSD_ACTIVITY
#                        HD_RECYCLER_STORAGE    <- RECYCLER_ACTIVITY
#                        HD_RECYCLER_NONSTORAGE <- RECYCLER_ACTIVITY_NONSTORAGE
#                        HD_IMPORTER            <- IMPORTER_ACTIVITY
#                        HD_RECOGNIZED_TRADER_IMPORTER <- RECOGNIZED_TRADER_IMPORTER
#                        HD_RECOGNIZED_TRADER_EXPORTER <- RECOGNIZED_TRADER_EXPORTER
#                        HD_SLAB_IMPORTER       <- SLAB_IMPORTER
#                        HD_SLAB_EXPORTER       <- SLAB_EXPORTER
#                        HD_TRANSPORTER         <- TRANSPORTER
#                        HD_TRANSFER_FACILITY   <- TRANSFER_FACILITY
#                        HD_ONSITE_BURNER_EXEMPTION <- ONSITE_BURNER_EXEMPTION
#                        HD_FURNACE_EXEMPTION   <- FURNACE_EXEMPTION
#                        HD_UNDERGROUND_INJECTION_ACTIVITY <- UNDERGROUND_INJECTION_ACTIVITY
#                        HD_OFF_SITE_RECEIPT    <- OFF_SITE_RECEIPT
#                        HD_UNIVERSAL_WASTE_LQ_HANDLER    <- LQHUW
#                        HD_UNIVERSAL_WASTE_DEST_FACILITY <- UNIVERSAL_WASTE_DEST_FACILITY
#                        HD_USED_OIL_* (7)      <- USED_OIL_* (TRANSPORTER,
#                          TRANSFER_FACILITY, PROCESSOR, REFINER, BURNER,
#                          MARKET_BURNER, SPEC_MARKETER)
#   NAICS4             Facility-year industry codes from the FULL NAICS_SEQ
#   NAICS6_1..NAICS6_4 listing (normalized and validated), receive-year based
#                      with carry from the nearest earlier coded year; see
#                      naics_facility_year() in 00_panel_functions.R for the
#                      whole rule. NAICS4 is the first four digits of the winner
#                      submission's lowest-seq code; NAICS6_1-4 are the first
#                      four distinct codes ordered by NAICS_SEQ then submission
#                      duration. Not conflict variables (multi-code listings are
#                      a form feature).
#   HD_RECORD_COUNT    Number of HD_MASTER source records (distinct
#                      SOURCE_TYPE x SEQ_NUMBER) CLASSIFIED to the row's report
#                      year, pooled across all source types; 0 if none. B/R
#                      records classify by REPORT_CYCLE (their filings arrive
#                      mostly the following even year), all others by receive
#                      year.
#
# BR_* come from BR_REPORTING_<cycle> (waste-line level, aggregated to the
# facility-year). HD_* come from the handler notification history in HD_MASTER
# and are independent of the BR filing, so they can legitimately disagree with
# BR_GENERATOR / BR_TSDF.
#
# Conflict resolution: see the three-tier design note in 00_panel_functions.R.
# The two 2015 non-convertible state-generator cases (KYR000029207 D|S,
# LAR000053413 7|N) were manually reviewed and confirmed to the convertible
# partner (S and N) -- exactly what the rule yields.
#
# Requires: tidyverse (incl. lubridate)
# =============================================================================

# Load the shared panel functions (loads tidyverse as a side effect) and every
# constant table (severity maps, HD attribute map, output column order).
source("code/modules/03_panels/rcrainfo/00_panel_functions.R")

# Build the balanced BR panel end to end. balanced = TRUE means only handlers
# recognized as LQG/TSDF in ALL five cycles are kept (5 rows per handler).
build_br_panel(
  balanced = TRUE,
  out_file = "output/panels/BR_PANEL_2015_2023_BALANCED/BR_PANEL_2015_2023_BALANCED.csv")
