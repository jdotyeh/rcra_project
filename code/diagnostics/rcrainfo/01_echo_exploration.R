library(tidyverse)
library(lubridate)

# ── Load data ─────────────────────────────────────────────────────────────────

complete   <- read_csv("data/echo_rcra_pipeline/PIPELINE_00_COMPLETE.csv",
                       col_types = cols(REGISTRY_ID = col_character(),
                                        SOURCE_ID   = col_character(),
                                        .default    = col_character()))

facilities <- read_csv("data/echo_rcra/RCRA_FACILITIES.csv",
                       col_types = cols(ID_NUMBER = col_character(),
                                        .default  = col_character()))

viosnc     <- read_csv("data/echo_rcra/RCRA_VIOSNC_HISTORY.csv",
                       col_types = cols(ID_NUMBER = col_character(),
                                        YRMONTH   = col_character(),
                                        .default  = col_character()))

# Parse dates
complete <- complete |>
  mutate(across(c(EVAL_DATE, VIOL_DETERMINED_DATE, ACTUAL_RTC_DATE,
                  ENF_ACTION_DATE), ~ mdy(.x)))

# ── RCRA_FACILITIES ───────────────────────────────────────────────────────────

# Facility types
facilities |>
  count(HREPORT_UNIVERSE_RECORD, sort = TRUE) |>
  print(n = 23)

# Active vs inactive
facilities |>
  count(ACTIVE_SITE, sort = TRUE) |>
  print(n = 27)

# Active facilities only
active_facilities <- facilities |>
  filter(str_detect(ACTIVE_SITE, "^H"))  # "H----" = active handler

cat("Active facilities:", nrow(active_facilities), "\n")
cat("Total facilities:", nrow(facilities), "\n")

# Operating TSDFs
facilities |>
  filter(str_trim(OPERATING_TSDF) != "------") |>
  count(OPERATING_TSDF, sort = TRUE)

# ── PIPELINE_00_COMPLETE ──────────────────────────────────────────────────────

# Basic shape: how many unique evaluations, facilities
cat("Total rows:", nrow(complete), "\n")
cat("Unique evaluations (ISN_RCR_EVAL):", n_distinct(complete$ISN_RCR_EVAL), "\n") # nolint
cat("Unique facilities (SOURCE_ID):",     n_distinct(complete$SOURCE_ID), "\n")

# Pipeline vs non-pipeline evaluations
complete |>
  distinct(ISN_RCR_EVAL, PIPELINE_FLAG) |>
  count(PIPELINE_FLAG)

# Inspection types
complete |>
  distinct(ISN_RCR_EVAL, EVAL_TYPE_DESC) |>
  count(EVAL_TYPE_DESC, sort = TRUE) |>
  print(n = 15)

# Inspections over time (by year)
complete |>
  distinct(ISN_RCR_EVAL, EVAL_DATE) |>
  mutate(year = year(EVAL_DATE)) |>
  count(year) |>
  print(n = 20)

# State-level inspection counts
complete |>
  distinct(ISN_RCR_EVAL, EVAL_ACTIVITY_LOCATION) |>
  count(EVAL_ACTIVITY_LOCATION, sort = TRUE) |>
  print(n = 15)

# Lead agency breakdown
complete |>
  distinct(ISN_RCR_EVAL, EVAL_LEAD_AGENCY) |>
  count(EVAL_LEAD_AGENCY, sort = TRUE)

# ── Violations ────────────────────────────────────────────────────────────────

# Share of inspections with a violation found
complete |>
  distinct(ISN_RCR_EVAL, FOUND_VIOLATION) |>
  count(FOUND_VIOLATION)

# Most common violation types
complete |>
  filter(!is.na(VIOL_TYPE)) |>
  count(VIOL_TYPE, sort = TRUE) |>
  print(n = 20)

# Time to return to compliance (days)
complete |>
  filter(!is.na(ACTUAL_RTC_DATE), !is.na(VIOL_DETERMINED_DATE)) |>
  mutate(days_to_rtc = as.numeric(ACTUAL_RTC_DATE - VIOL_DETERMINED_DATE)) |>
  filter(days_to_rtc >= 0) |>
  summarise(
    median_days = median(days_to_rtc),
    mean_days   = mean(days_to_rtc),
    p25         = quantile(days_to_rtc, 0.25),
    p75         = quantile(days_to_rtc, 0.75),
    p90         = quantile(days_to_rtc, 0.90)
  )

# ── Enforcement actions ───────────────────────────────────────────────────────

# Share of inspections with enforcement
complete |>
  distinct(ISN_RCR_EVAL, ENF_TYPE_DESC) |>
  mutate(has_enf = !is.na(ENF_TYPE_DESC)) |>
  count(has_enf)

# Enforcement action types
complete |>
  filter(!is.na(ENF_TYPE_DESC)) |>
  distinct(ISN_RCR_EVAL, ENF_TYPE_DESC) |>
  count(ENF_TYPE_DESC, sort = TRUE) |>
  print(n = 15)

# Penalty amounts
complete |>
  filter(!is.na(PENALTY_AMOUNT)) |>
  mutate(penalty = as.numeric(PENALTY_AMOUNT)) |>
  filter(penalty > 0) |>
  summarise(
    n       = n(),
    median  = median(penalty),
    mean    = mean(penalty),
    p90     = quantile(penalty, 0.90),
    max     = max(penalty),
    total   = sum(penalty)
  )

# ── RCRA_VIOSNC_HISTORY ───────────────────────────────────────────────────────

# Parse year-month
viosnc <- viosnc |>
  mutate(
    year  = as.integer(str_sub(YRMONTH, 1, 4)),
    month = as.integer(str_sub(YRMONTH, 5, 6)),
    date  = ymd(paste0(YRMONTH, "01"))
  )

# Date range covered
cat("VioSNC date range:", format(min(viosnc$date)), "to", format(max(viosnc$date)), "\n") # nolint

# How many facilities appear in the history
cat("Unique facilities in VioSNC:", n_distinct(viosnc$ID_NUMBER), "\n")

# Snapshot count per facility (flag sparse ones)
snaps_per_facility <- viosnc |>
  count(ID_NUMBER, name = "n_snapshots")

snaps_per_facility |>
  summarise(
    median_snaps = median(n_snapshots),
    mean_snaps   = mean(n_snapshots),
    pct_sparse   = mean(n_snapshots <= 6)   # ≤6 months ever recorded
  )

# Monthly share of facilities in violation / SNC
viosnc |>
  group_by(YRMONTH) |>
  summarise(
    pct_vio = mean(VIO_FLAG == "Y", na.rm = TRUE),
    pct_snc = mean(SNC_FLAG == "Y", na.rm = TRUE)
  ) |>
  arrange(YRMONTH) |>
  print(n = 20)
