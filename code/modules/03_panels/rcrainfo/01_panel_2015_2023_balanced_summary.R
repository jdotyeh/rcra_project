# =============================================================================
# FILE:     01_panel_2015_2023_balanced_summary.R
# PURPOSE:  Produce numeric and categorical descriptive summaries of the balanced
#           BR panel, as CSVs and a two-sheet workbook.
# INPUTS:   output/panels/BR_PANEL_2015_2023_BALANCED/BR_PANEL_2015_2023_BALANCED.csv
# OUTPUTS:  output/panels/summary/panel_numeric_summary.csv,
#           output/panels/summary/panel_categorical_summary.csv,
#           output/panels/summary/BR_PANEL_2015_2023_Summary.xlsx
# AUTHOR:   Jason Ye
# CREATED:  2026-07-10
# UPDATED:  2026-07-10
# =============================================================================
#
# Simple descriptive summaries of BR_PANEL_2015_2023_BALANCED.csv.
#   Numeric      : N, % missing, min, p5, median, mean, p95, max.
#   Categorical  : full distribution of EVERY category with n and % (of all
#                  rows), missing shown as its own "(Missing)" row.
# High-cardinality identifiers / free-text (HANDLER_ID, FRS_ID,
# HD_LOCATION_COUNTY, the NAICS4/NAICS6_* codes) are not enumerated; NAICS is
# summarized at the 2-digit sector level (from NAICS4) instead.
#
# Writes long-format CSVs + a 2-sheet workbook under output/panels/summary/.
# Requires: tidyverse (+ openxlsx2 for the .xlsx; skipped if unavailable).
# =============================================================================

# Load the tidyverse; the summary script does not need the shared panel helpers.
library(tidyverse)

# Balanced panel CSV to summarize, and the output folder for the summary files.
panel_file <- "output/panels/BR_PANEL_2015_2023_BALANCED/BR_PANEL_2015_2023_BALANCED.csv"
out_dir    <- "output/panels/summary"
# Read everything as character; per-variable casts happen when needed.
p <- read_csv(panel_file, col_types = cols(.default = "c"))
# Total rows (facility x cycle observations); used as the pct_missing denominator.
N <- nrow(p)

# Numeric variables to describe with min/median/max and quantiles.
num_vars <- c("BR_GENERATE_TONS", "BR_MANAGE_TONS", "BR_SHIP_TONS", "BR_RECEIVE_TONS",
              "HD_RECORD_COUNT", "HD_LOCATION_LATITUDE", "HD_LOCATION_LONGITUDE",
              "HD_PREFERRED_LATITUDE", "HD_PREFERRED_LONGITUDE")

# Every low/medium-cardinality categorical to enumerate in full.
cat_vars <- c("REPORT_CYCLE", "BR_GENERATOR", "BR_TSDF",
              # The coordinate slot sources, which is where the count of
              # facilities carrying an alternate pair at all can be read off.
              "HD_PREFERRED_COORD_SOURCE", "HD_COORD_SOURCE_2",
              "HD_COORD_SOURCE_3", "HD_COORD_SOURCE_4", "HD_COORD_SOURCE_5",
              "HD_EPA_REGION", "HD_ACTIVITY_STATE", "HD_LOCATION_STATE",
              "HD_GENERATOR", "HD_STATE_GENERATOR", "HD_SHORT_TERM_GENERATOR",
              "HD_TSDF", "HD_RECYCLER_STORAGE", "HD_RECYCLER_NONSTORAGE",
              "HD_IMPORTER", "HD_RECOGNIZED_TRADER_IMPORTER", "HD_RECOGNIZED_TRADER_EXPORTER",
              "HD_SLAB_IMPORTER", "HD_SLAB_EXPORTER",
              "HD_TRANSPORTER", "HD_TRANSFER_FACILITY",
              "HD_ONSITE_BURNER_EXEMPTION", "HD_FURNACE_EXEMPTION",
              "HD_UNDERGROUND_INJECTION_ACTIVITY", "HD_OFF_SITE_RECEIPT",
              "HD_UNIVERSAL_WASTE_LQ_HANDLER", "HD_UNIVERSAL_WASTE_DEST_FACILITY",
              "HD_USED_OIL_TRANSPORTER", "HD_USED_OIL_TRANSFER_FACILITY",
              "HD_USED_OIL_PROCESSOR", "HD_USED_OIL_REFINER", "HD_USED_OIL_BURNER",
              "HD_USED_OIL_MARKET_BURNER", "HD_USED_OIL_SPEC_MARKETER")

# -- Numeric summary ----------------------------------------------------------
# Build a one-row summary per numeric variable, then row-bind them all.
num_summary <- map(num_vars, function(v) {
  # Cast the character column to numeric; unparseable strings become NA.
  x  <- suppressWarnings(as.numeric(p[[v]]))
  # Missing count and the non-missing subset for the quantiles/mean.
  nm <- sum(is.na(x)); xn <- x[!is.na(x)]
  # Requested quantiles: min, p5, median, p95, max.
  q  <- quantile(xn, c(0, .05, .5, .95, 1), names = FALSE)
  # pct_missing divides by TOTAL rows (N); note tibble() evaluates args in order,
  # so the local `N = length(xn)` below must NOT be the denominator.
  tibble(variable = v, N = length(xn), pct_missing = round(100 * nm / nrow(p), 1),
         min = q[1], p5 = q[2], median = q[3],
         mean = mean(xn), p95 = q[4], max = q[5])
}) |>
  list_rbind() |>
  # Round the numeric outputs to 4 decimals for a readable table.
  mutate(across(c(min, p5, median, mean, p95, max), \(z) round(z, 4)))

# -- Categorical distributions (all categories, n + pct) ----------------------
# NAICS enumerated at 2-digit sector level (from NAICS4), not the raw codes.
p <- mutate(p, HD_NAICS_SECTOR = if_else(is.na(NAICS4), NA_character_,
                                         substr(NAICS4, 1, 2)))
# Every categorical to enumerate, including the derived sector column.
cat_all <- c(cat_vars, "HD_NAICS_SECTOR")

# Enumerate one variable: every category with a count, "(Missing)" sinks to the bottom.
one_cat <- function(v) {
  # Treat empty strings as missing so they count with the NAs.
  x <- p[[v]]; x[x == ""] <- NA
  tibble(value = x) |>
    # Missing rows collapse into a single "(Missing)" bucket.
    mutate(value = if_else(is.na(value), "(Missing)", value)) |>
    # Tally per category.
    count(value, name = "n") |>
    mutate(is_miss = value == "(Missing)") |>
    arrange(is_miss, desc(n)) |>          # frequency desc, "(Missing)" last
    # Rename to the output schema and compute the percentage against total rows.
    transmute(variable = v, category = value, n,
              pct = round(100 * n / N, 2))
}
# Run one_cat() over every categorical and stack the results.
cat_summary <- map(cat_all, one_cat) |> list_rbind()

# -- Write --------------------------------------------------------------------
# Ensure the summary folder exists, then write the numeric and categorical CSVs.
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
write_csv(num_summary, file.path(out_dir, "panel_numeric_summary.csv"))
write_csv(cat_summary, file.path(out_dir, "panel_categorical_summary.csv"))

# Two-sheet Excel workbook alongside the CSVs when openxlsx2 is available.
if (requireNamespace("openxlsx2", quietly = TRUE)) {
  wb <- openxlsx2::wb_workbook()
  wb$add_worksheet("Numeric")$add_data(x = num_summary)
  wb$add_worksheet("Categorical")$add_data(x = cat_summary)
  openxlsx2::wb_save(wb, file.path(out_dir, "BR_PANEL_2015_2023_Summary.xlsx"), overwrite = TRUE)
}

# Console echo of the results so a manual run shows the tables immediately.
cat(sprintf("Panel rows: %s\n\n== NUMERIC ==\n", format(N, big.mark = ",")))
print(as.data.frame(num_summary), row.names = FALSE)
cat("\n== CATEGORICAL (n, pct of all rows) ==\n")
# Print each categorical variable as its own block for readability.
cat_summary |>
  group_split(variable) |>
  walk(function(d) {
    cat("\n[", d$variable[1], "]  (", nrow(d), "categories)\n", sep = "")
    print(as.data.frame(d[c("category", "n", "pct")]), row.names = FALSE)
  })
# Confirmation footer.
cat(sprintf("\nWrote CSVs + xlsx to %s/\n", out_dir))
