# =============================================================================
# 01_panel_2015_2023_balanced_summary.R
#
# Simple descriptive summaries of BR_PANEL_2015_2023_BALANCED.csv.
#   Numeric      : N, % missing, min, p5, median, mean, p95, max.
#   Categorical  : full distribution of EVERY category with n and % (of all
#                  rows), missing shown as its own "(Missing)" row.
# High-cardinality identifiers / free-text (HANDLER_ID, FRS_ID, HD_CONFLICTS,
# HD_LOCATION_COUNTY, raw HD_NAICS_CODE) are not enumerated; NAICS is summarized
# at the 2-digit sector level instead.
#
# Writes long-format CSVs + a 2-sheet workbook under output/panels/summary/.
# Requires: tidyverse (+ openxlsx2 for the .xlsx; skipped if unavailable).
# =============================================================================

library(tidyverse)

panel_file <- "output/panels/BR_PANEL_2015_2023_BALANCED.csv"
out_dir    <- "output/panels/summary"
p <- read_csv(panel_file, col_types = cols(.default = "c"))
N <- nrow(p)

num_vars <- c("BR_GENERATE_TONS", "BR_MANAGE_TONS", "BR_SHIP_TONS", "BR_RECEIVE_TONS",
              "HD_RECORD_COUNT", "HD_LOCATION_LATITUDE", "HD_LOCATION_LONGITUDE")

# Every low/medium-cardinality categorical to enumerate in full.
cat_vars <- c("REPORT_CYCLE", "BR_GENERATOR", "BR_TSDF",
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
num_summary <- map(num_vars, function(v) {
  x  <- suppressWarnings(as.numeric(p[[v]]))
  nm <- sum(is.na(x)); xn <- x[!is.na(x)]
  q  <- quantile(xn, c(0, .05, .5, .95, 1), names = FALSE)
  # pct_missing divides by TOTAL rows (N); note tibble() evaluates args in order,
  # so the local `N = length(xn)` below must NOT be the denominator.
  tibble(variable = v, N = length(xn), pct_missing = round(100 * nm / nrow(p), 1),
         min = q[1], p5 = q[2], median = q[3],
         mean = mean(xn), p95 = q[4], max = q[5])
}) |>
  list_rbind() |>
  mutate(across(c(min, p5, median, mean, p95, max), \(z) round(z, 4)))

# -- Categorical distributions (all categories, n + pct) ----------------------
# NAICS enumerated at 2-digit sector level, not the raw code.
p <- mutate(p, HD_NAICS_SECTOR = if_else(is.na(HD_NAICS_CODE), NA_character_,
                                         substr(HD_NAICS_CODE, 1, 2)))
cat_all <- c(cat_vars, "HD_NAICS_SECTOR")

one_cat <- function(v) {
  x <- p[[v]]; x[x == ""] <- NA
  tibble(value = x) |>
    mutate(value = if_else(is.na(value), "(Missing)", value)) |>
    count(value, name = "n") |>
    mutate(is_miss = value == "(Missing)") |>
    arrange(is_miss, desc(n)) |>          # frequency desc, "(Missing)" last
    transmute(variable = v, category = value, n,
              pct = round(100 * n / N, 2))
}
cat_summary <- map(cat_all, one_cat) |> list_rbind()

# -- Write --------------------------------------------------------------------
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
write_csv(num_summary, file.path(out_dir, "panel_numeric_summary.csv"))
write_csv(cat_summary, file.path(out_dir, "panel_categorical_summary.csv"))

if (requireNamespace("openxlsx2", quietly = TRUE)) {
  wb <- openxlsx2::wb_workbook()
  wb$add_worksheet("Numeric")$add_data(x = num_summary)
  wb$add_worksheet("Categorical")$add_data(x = cat_summary)
  openxlsx2::wb_save(wb, file.path(out_dir, "BR_PANEL_2015_2023_Summary.xlsx"), overwrite = TRUE)
}

cat(sprintf("Panel rows: %s\n\n== NUMERIC ==\n", format(N, big.mark = ",")))
print(as.data.frame(num_summary), row.names = FALSE)
cat("\n== CATEGORICAL (n, pct of all rows) ==\n")
cat_summary |>
  group_split(variable) |>
  walk(function(d) {
    cat("\n[", d$variable[1], "]  (", nrow(d), "categories)\n", sep = "")
    print(as.data.frame(d[c("category", "n", "pct")]), row.names = FALSE)
  })
cat(sprintf("\nWrote CSVs + xlsx to %s/\n", out_dir))
