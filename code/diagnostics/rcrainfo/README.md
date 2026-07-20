# RCRAInfo Diagnostics

Thirty standalone scripts that probe, cross-check, and prototype against the
RCRAInfo data before the replication pipeline settled its rules. They were
migrated from the exploratory repository `rcra-regulatory-data-infrastructure`
and rewritten to read this repository's appended files under `data/rcrainfo/`
and the ECHO downloads under `data/echo_rcra/` and `data/echo_rcra_pipeline/`.
The master script never runs them, and nothing in the pipeline depends on what
they write. Everything they produce lands in `output/diagnostics/`.

Run any script from the repository root, for example
`Rscript code/diagnostics/rcrainfo/10_br_facility_cycles.R`. Scripts inside a
group are numbered in dependency order, so run the lower numbers of a group
first when a script reads another script's output.

## Exploration and Data Quality

Scripts 01 through 04 stand alone. `01_echo_exploration.R` is a first pass over
the ECHO downloads that tabulates facility types, inspection and enforcement
activity, penalties, time to return to compliance, and the monthly violation
share in `RCRA_VIOSNC_HISTORY.csv`. `02_exact_duplicates.R` is a small engine
that checks any raw file for byte-identical duplicate rows after you set the
`target` file-name prefix at the top. `03_hd_reporting_integrity.R` sweeps
`HD_REPORTING.csv` for key collisions, malformed handler IDs, coordinate and
date anomalies, and placeholder names, writing flagged samples beside its
console report. `04_hd_multi_handler_sites.R` extracts the groups where one
facility name and coordinate pair carries several distinct handler IDs.

## Master File Prototypes

Scripts 05 through 09 predate the pipeline's master-file stage and are kept as
prototypes. `05_hd_master_feasibility.R` measures how many facilities would
survive as a single row if every handler sub-table were joined onto
`HD_HANDLER.csv`. `06_hd_episodic_master.R` and `07_hd_hsm_master.R` full-join
the four episodic-event tables and the four hazardous-secondary-material tables
into merged wide files. `08_ce_master_prototype.R` is the forerunner of the
pipeline's `02_ce_master.R` and joins `CE_REPORTING.csv` with `CE_CITATION.csv`;
`09_ce_master_data_dictionary.R` then documents that prototype by scraping the
EPA public data element dictionary, so it needs both network access and the
output of script 08.

## Reconciling the Biennial Report with the Handler Module

Scripts 10 through 18 form one chain that asks whether the handler-cycle
combinations in the Biennial Report and in the handler module agree.
`10_br_facility_cycles.R` collapses every Biennial Report cycle to one row per
facility and cycle with its page counts, national-report flags, and form flags,
and `11_br_facility_cycles_dedup.R` resolves the thirteen duplicated
handler-cycles case by case. `12_hd_handler_b_cycles.R` and
`14_hd_handler_r_cycles.R` pull the source type `B` and source type `R` rows of
`HD_HANDLER.csv` and derive a `REPORT CYCLE` from the receive-date year, and
`13_hd_handler_b_dedup.R` collapses the `B` rows that repeat a handler-cycle
with identical activity flags. `15_br_hd_overlap.R` splits the two sides into
both, Biennial Report only, and handler only, and `16_br_only_hd_window.R`
pulls the handler rows received inside each orphan cycle's filing window to
explain the Biennial Report only cases. `17_br_hd_venn_figure.R` draws the
area-true Venn diagram of that comparison and `18_br_filter_flow_figure.R`
draws the concept figure of how self-reported generator categories funnel into
the Biennial Report and get recalculated.

## LQG Coverage

Scripts 19 through 22 measure how completely the Biennial Report captures
federal LQGs. `19_lqg_universe.R` counts the facilities
flagged `FED WASTE GENERATOR == "1"` on any form received during 2015 to 2023
and checks which of them ever file as calculated status `L`.
`20_lqg_gap_diagnose.R` characterizes the missing set and
`21_lqg_gap_verify.R` verifies each candidate explanation with traced real
examples. `22_lqg_reverse_check.R` runs the reverse direction and asks which
calculated-`L` filers never carry the registration flag.

## Panel Prototypes

Scripts 23 through 27 are the prototype of what became the `03_panels` stage,
and they differ from it on purpose because they build the at-least-once
universe rather than the balanced one. `23_panel_facilities.R` defines the
facility set and the cycle-specific `LQG` and `TSDF` dummies and writes
`coherent_panel_facilities.csv`, which every later script in this group reads.
`24_br_panel_prototype.R` stacks the full Biennial Report lines for that set,
`25_panel_profile.R` profiles the set against the full handler universe,
`26_panel_violations.R` attaches ECHO violation counts and dummies, and
`27_lqg_strict_all5.R` builds the strict subset that is LQG in all five cycles
under both definitions.

## Reference Tables and Figures

Scripts 28 through 30 stand alone. `28_module_variable_matrix.R` builds the
variable-presence matrices for the handler and permitting modules in both
orientations, using the merged files from scripts 06 and 07 when they exist.
`29_literature_review_matrix.R` renders the hard-coded literature review into a
workbook and a markdown twin. `30_br_facility_trend_figure.R` plots the
distinct-facility count per Biennial Report cycle with presidential
administrations shaded behind the line.

## Caveats Worth Knowing

The figure scripts 17 and 30 embed numbers copied from earlier console runs of
scripts 15 and 10, so those constants must be refreshed by hand after the
upstream scripts are rerun. Script 11 carries a conflict-resolution branch for
`CALCULATED GENERATOR STATUS` even though script 10 does not emit that column,
so the branch is inert unless the column is added to the grouping keys. Script
13 also deduplicates an optional `HD_HANDLER_B_dup_handler_cycle.csv` that only
exists if an earlier ad-hoc split produced it, and it skips the file cleanly
when absent. Script 09 reaches the live EPA help site, so its output can change
whenever EPA revises the dictionary.
