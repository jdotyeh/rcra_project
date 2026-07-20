# =============================================================================
# 24_br_panel_prototype.R
#
# Build the BIENNIAL-REPORT PANEL for academic economic research.
#
# For the coherent set of facilities (at-least-once panel of LQG-reporting
# sites over the odd cycles 2015-2023; see
# code/diagnostics/rcrainfo/23_panel_facilities.R), this stacks the FULL
# biennial-report records - every BR column, every line (1 row per waste form /
# management line) - cycle by cycle, so the researcher keeps all underlying
# information and can construct their own variables.
#
# Two YEAR-SPECIFIC dummies are added (econometric 0/1, not TRUE/FALSE):
#     LQG   = 1 if the facility was a Large Quantity Generator IN THAT CYCLE
#     TSDF  = 1 if the facility had TSD activity        IN THAT CYCLE
# (status comes from the contemporaneous HD_HANDLER record, NOT today's status,
#  so a site that was an LQG in 2015 but is an SQG now is LQG=1 in 2015.)
# SQG-status years are the implicit baseline (LQG = 0, TSDF = 0); a site may be
# both (LQG = 1, TSDF = 1).
#
# Columns are UNIONED across cycles (2023 adds COUNTRY CODE / MIXED WASTE, etc.);
# fields absent in a given cycle are filled NA so nothing is dropped.
#
# Also writes a SEPARATE file of "page-split" lines: rows that are identical on
# (HANDLER_ID, year, BR_FORM, DESCRIPTION, SOURCE_CODE, FORM_CODE,
# MANAGEMENT_METHOD) but split across more than one (HZ_PG, SUB_PAGE_NUM) - i.e.
# the same waste/management reported on multiple report pages, typically with
# different quantities.
#
# Output  ->  output/diagnostics/
#
# Requires: tidyverse (readr, dplyr, purrr, stringr, tibble)
# =============================================================================

library(readr)
library(dplyr)
library(purrr)
library(stringr)
library(tibble)

# ---- Facility set + year-specific status ------------------------------------
# Sources 23_panel_facilities.R, which leaves in the environment:
#   coherent_facilities      - HANDLER_ID (at-least-once universe)
#   facility_status_by_year  - HANDLER_ID x year with year-specific LQG / TSDF
source("code/diagnostics/rcrainfo/23_panel_facilities.R")

keep_ids   <- coherent_facilities$HANDLER_ID
year_flags <- facility_status_by_year |> select(HANDLER_ID, year, LQG, TSDF)

# ---- Parameters -------------------------------------------------------------
PANEL_YEARS    <- seq(2015L, 2023L, by = 2L)
BR_DIR         <- "data/rcrainfo/br"
OUT_PANEL      <- "output/diagnostics/biennial_report_panel_2015_2023.csv"
OUT_PAGESPLIT  <- "output/diagnostics/br_panel_page_split_lines.csv"

# Columns that define "the same waste / management line" (per request).
SAME_KEY <- c("HANDLER_ID", "year", "BR_FORM", "DESCRIPTION",
              "SOURCE_CODE", "FORM_CODE", "MANAGEMENT_METHOD")

clean_names <- function(df) rename_with(df, ~ str_replace_all(.x, " ", "_"))

# ---- Pull full BR records for the coherent facilities, cycle by cycle -------
read_year_panel <- function(year) {
  f <- file.path(BR_DIR, sprintf("BR_REPORTING_%d.csv", year))
  stopifnot(file.exists(f))
  rows <- read_csv(f, col_types = cols(.default = col_character()),
                   show_col_types = FALSE, progress = FALSE) |>
    clean_names() |>
    filter(HANDLER_ID %in% keep_ids) |>
    mutate(year = year, .after = HANDLER_ID)
  message(sprintf("  %d: %s BR lines for %s facilities",
                  year, format(nrow(rows), big.mark = ","),
                  format(n_distinct(rows$HANDLER_ID), big.mark = ",")))
  rows
}

message("Extracting full biennial-report records for the coherent panel ...")
panel <- map(PANEL_YEARS, read_year_panel) |>
  bind_rows() |>                                   # union of columns across cycles
  left_join(year_flags, by = c("HANDLER_ID", "year")) |>
  relocate(LQG, TSDF, .after = year)

# ---- Write the panel --------------------------------------------------------
dir.create("output/diagnostics", showWarnings = FALSE, recursive = TRUE)
write_csv(panel, OUT_PANEL)

message("\n================ BIENNIAL REPORT PANEL ================")
message(sprintf("Facilities : %s", format(n_distinct(panel$HANDLER_ID), big.mark = ",")))
message(sprintf("Rows       : %s (BR waste-form / management lines)", format(nrow(panel), big.mark = ",")))
message(sprintf("Columns    : %d", ncol(panel)))
message("Rows per cycle:");                 print(count(panel, year))
message("Year-specific dummy combination (LQG, TSDF) over facility-years:")
print(panel |> distinct(HANDLER_ID, year, LQG, TSDF) |> count(LQG, TSDF))
message(sprintf("Written -> %s", OUT_PANEL))

# ---- Extract "page-split" lines ---------------------------------------------
# Within each SAME_KEY group, flag groups that have >1 row AND span >1 distinct
# (HZ_PG, SUB_PAGE_NUM).  Output every row in such groups, plus group diagnostics,
# sorted so the members of a group sit together.
message("\nIdentifying page-split lines (same waste/management, different HZ_PG / SUB_PAGE_NUM) ...")
page_split <- panel |>
  group_by(across(all_of(SAME_KEY))) |>
  mutate(
    grp_n_rows       = n(),
    grp_n_page_combo = n_distinct(paste(HZ_PG, SUB_PAGE_NUM, sep = "|")),
    grp_n_qty_combo  = n_distinct(paste(GENERATION_TONS, MANAGED_TONS,
                                        SHIPPED_TONS, RECEIVED_TONS, sep = "|"))
  ) |>
  ungroup() |>
  filter(grp_n_rows > 1, grp_n_page_combo > 1) |>
  mutate(page_split_group_id = match(do.call(paste, c(across(all_of(SAME_KEY)), sep = "")),
                                     unique(do.call(paste, c(across(all_of(SAME_KEY)), sep = ""))))) |>
  relocate(page_split_group_id, grp_n_rows, grp_n_page_combo, grp_n_qty_combo,
           .after = year) |>
  arrange(page_split_group_id, HZ_PG, SUB_PAGE_NUM)

write_csv(page_split, OUT_PAGESPLIT)

message("================ PAGE-SPLIT LINES ================")
message(sprintf("Groups (same key, multi-page) : %s",
                format(n_distinct(page_split$page_split_group_id), big.mark = ",")))
message(sprintf("Rows in those groups          : %s of %s panel rows (%.1f%%)",
                format(nrow(page_split), big.mark = ","),
                format(nrow(panel), big.mark = ","),
                100 * nrow(page_split) / nrow(panel)))
message("Rows per cycle (page-split):"); print(count(page_split, year))
message(sprintf("Written -> %s", OUT_PAGESPLIT))
