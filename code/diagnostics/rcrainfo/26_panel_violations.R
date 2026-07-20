# =============================================================================
# 26_panel_violations.R
#
# For the coherent panel of facilities
# (output/diagnostics/coherent_panel_facilities.csv), pull every RCRA violation
# row determined in the study window 2015-2023 (inclusive) and attach two
# facility-level fields immediately after the ID:
#
#   has_violation  - dummy (1 if the facility had >=1 violation in 2015-2023,
#                    else 0)
#   n_violations   - count of violation rows for the facility in 2015-2023
#
# Facilities with no violations in the window are kept, with has_violation = 0
# and n_violations = 0.
#
# Writes:
#   output/diagnostics/panel_violations_2015_2023.csv     - the extracted
#                                                           violation rows
#   output/diagnostics/facility_violations_2015_2023.csv  - one row per panel
#                                                           facility w/ dummies
# =============================================================================

library(readr)
library(dplyr)
library(lubridate)

# --- 1. Panel facility universe ---------------------------------------------
panel <- read_csv("output/diagnostics/coherent_panel_facilities.csv",
                  col_types = cols(.default = col_character()))

panel_ids <- unique(panel$HANDLER_ID)

# --- 2. Violations: keep panel facilities, window 2015-2023 -----------------
violations <- read_csv(
  "data/echo_rcra/RCRA_VIOLATIONS.csv",
  col_types = cols(.default = col_character())
)

panel_violations <- violations |>
  mutate(
    viol_date = mdy(DATE_VIOLATION_DETERMINED),
    viol_year = year(viol_date)
  ) |>
  filter(
    ID_NUMBER %in% panel_ids,
    !is.na(viol_year),
    viol_year >= 2015,
    viol_year <= 2023
  )

write_csv(panel_violations, "output/diagnostics/panel_violations_2015_2023.csv")

# --- 3. Facility-level dummies ----------------------------------------------
viol_summary <- panel_violations |>
  group_by(HANDLER_ID = ID_NUMBER) |>
  summarise(n_violations = n(), .groups = "drop")

facility_violations <- tibble::tibble(HANDLER_ID = panel_ids) |>
  left_join(viol_summary, by = "HANDLER_ID") |>
  mutate(
    n_violations  = tidyr::replace_na(n_violations, 0L),
    has_violation = as.integer(n_violations > 0)
  ) |>
  # dummies immediately after the ID
  select(HANDLER_ID, has_violation, n_violations)

write_csv(facility_violations,
          "output/diagnostics/facility_violations_2015_2023.csv")

# --- 4. Console summary ------------------------------------------------------
message(sprintf(
  "Panel facilities: %d | with >=1 violation 2015-2023: %d | violation rows: %d",
  nrow(facility_violations),
  sum(facility_violations$has_violation),
  nrow(panel_violations)
))
