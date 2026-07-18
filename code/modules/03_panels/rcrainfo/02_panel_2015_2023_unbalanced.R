# =============================================================================
# FILE:     02_panel_2015_2023_unbalanced.R
# PURPOSE:  Build the unbalanced counterpart of the balanced BR panel: every
#           handler recognized as LQG and/or TSDF in at least one cycle, one row
#           per qualifying cycle, by the same rules.
# INPUTS:   data/rcrainfo/br/BR_REPORTING_<cycle>.csv,
#           output/modular_master_files/HD_MASTER.csv,
#           data/frs/FRS_PROGRAM_LINKS.csv; sources 00_panel_functions.R
# OUTPUTS:  output/panels/BR_PANEL_2015_2023_UNBALANCED/BR_PANEL_2015_2023_UNBALANCED.csv
# AUTHOR:   Jason Ye
# CREATED:  2026-07-10
# UPDATED:  2026-07-16
# =============================================================================
#
# Facility-cycle panel of RCRA handlers recognized in the Biennial Report as
# large quantity generators (LQGs) and/or treatment, storage and disposal
# facilities (TSDFs), report cycles 2015-2023 (odd years only). One
# row per handler x cycle; UNBALANCED: every handler recognized as LQG and/or
# TSDF in AT LEAST ONE of the five cycles is kept, with a row only for the
# cycles in which it is recognized (1-5 rows per handler). The balanced
# counterpart (01_panel_2015_2023_balanced.R) keeps only handlers recognized in
# all five cycles; this panel is a strict superset of it, built by the same
# rules.
#
# All build logic lives in 00_panel_functions.R (build_br_panel() and its
# helpers); this script sets the panel's parameters and runs it. The columns
# are identical to the balanced panel and are documented in full in
# 01_panel_2015_2023_balanced.R.
#
# Requires: tidyverse (incl. lubridate)
# =============================================================================

source("code/modules/03_panels/rcrainfo/00_panel_functions.R")

build_br_panel(
  balanced = FALSE,
  out_file = "output/panels/BR_PANEL_2015_2023_UNBALANCED/BR_PANEL_2015_2023_UNBALANCED.csv")
