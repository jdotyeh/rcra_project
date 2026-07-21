# =============================================================================
# FILE:     master.R
# PURPOSE:  Run the whole project end to end. Discovers every script under
#           code/modules/ and sources them in path order, so the four numbered
#           stages run one after another with setup first.
# INPUTS:   all scripts under code/modules/ (00_setup through 04_summary_tables)
# OUTPUTS:  none of its own; each sourced script writes its own outputs under
#           data/ and output/
# AUTHOR:   Jason Ye
# CREATED:  2026-07-06
# UPDATED:  2026-07-07
# =============================================================================
#
# Modules live under code/modules/<stage>/<module>/. Sorting the discovered
# paths alphabetically gives the intended run order:
#   00_setup                 - install and load packages, create output folders
#   01_download/<source>     - download the raw EPA data and scrape dictionaries
#   02_modular_master_files  - one analysis-ready master CSV per RCRAInfo module
#   03_panels                - facility panels built from the master files
#   04_summary_tables        - per-module and per-cycle summary workbooks
#
# 00_setup sorts first, so packages and folders are ready before any stage runs.
# Helper scripts under code/utils/ are intentionally not discovered here; they
# are convenience tools, not part of the pipeline (see code/utils/README.md).
#
# Each script runs in its own environment so they cannot interfere with one
# another. Run from the repository root. The download stage pulls tens of GB, so
# a full pass takes hours. Supplementary-inventory download scripts under
# code/diagnostics/ are also not discovered here (see code/diagnostics/README.md).

# Walk code/modules/ recursively, keeping only .R files; sorting the paths
# alphabetically gives the intended stage-by-stage run order.
scripts <- sort(list.files("code/modules",
                           pattern = "\\.R$", full.names = TRUE, recursive = TRUE))

# build_panels.R is a standalone shortcut that re-runs the panel subset on its
# own. The full pipeline already builds the panels through the numbered stages,
# so exclude the orchestrator here to avoid doing that work twice.
scripts <- scripts[!grepl("/build_panels\\.R$", scripts)]

# Guard against being run from the wrong directory. The paths above are relative
# to the repository root, so a different working directory quietly discovers no
# scripts and the loop below would exit as a success having done nothing. Fail
# loudly instead of pretending the pipeline ran.
if (length(scripts) == 0) {
  stop("No scripts found under code/modules/. Run master.R from the repository root.",
       call. = FALSE)
}

# Source each script in a fresh environment so their globals stay isolated;
# the banner marks the boundary in the console log for easier debugging.
for (s in scripts) {
  cat("\n========", s, "========\n")
  source(s, local = new.env())
}
