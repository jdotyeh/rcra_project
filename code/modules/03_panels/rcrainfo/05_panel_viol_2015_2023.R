# =============================================================================
# FILE:     05_panel_viol_2015_2023.R
# PURPOSE:  Build the balanced facility-month panel of RCRA violations from
#           CE_MASTER, months 2015-01 through 2023-12, with the FRS link.
# INPUTS:   output/modular_master_files/CE_MASTER.csv,
#           data/frs/FRS_PROGRAM_LINKS.csv; sources 00_panel_functions.R
# OUTPUTS:  output/panels/CE_PANEL_2015_2023/VIOL_PANEL_2015_2023.csv
#           (+ .rds twin with exact column types)
# AUTHOR:   Jason Ye
# CREATED:  2026-07-21
# UPDATED:  2026-07-21
# =============================================================================
#
# Facility-month panel of RCRA violations built from CE_MASTER, calendar months
# 2015-01 through 2023-12. One row per handler x year x month, balanced over the
# full 108-month window for every handler with at least one violation determined
# in 2015-2023 (38,618 handlers x 108 months). Months with no violation carry
# zero counts and empty violation fields.
#
# A "violation" is one distinct combination of the RCRAInfo violation key
# (HANDLER_ID, VIOL_ACTIVITY_LOCATION, VIOL_SEQ, VIOL_DETERMINED_BY_AGENCY),
# which is the key the CM&E structure chart uses to link CE_CITATION back to the
# violation it belongs to. CE_MASTER repeats the violation across the evaluations
# that found it, the enforcement actions that address it, and its citation rows,
# and it is collapsed back to one row here. The key holds the violation's own
# attributes constant: across the whole file no key carries two values of
# VIOL_TYPE or RESPONSIBLE_AGENCY, and exactly one carries two values of
# DETERMINED_DATE or ACTUAL_RTC_DATE. The citation fields and the links to
# evaluations and enforcement actions are what does vary within the key, and they
# are aggregated over every row of the violation rather than read off the first
# one.
#
# Each violation is assigned to the panel month of DETERMINED_DATE, the date the
# agency determined the violation exists, which is populated and parseable on
# every violation record in the data, so no violation is dropped for a missing
# date. That date is not the evaluation date: over the 251,893 distinct pairs of
# a window violation and an evaluation linked to it, the determination falls
# after the evaluation start on 7.4 percent, on the same day on 77.3 percent, and
# before it on 15.3 percent, since a determination can follow sample results or a
# legal review and a single violation can be linked to several evaluations
# (14.4 percent of window violations are).
#
# Columns
#   HANDLER_ID, FRS_ID, YEAR, MONTH
#   FRS_ID             EPA Facility Registry Service REGISTRY_ID, linked from the
#                      FRS Program Links file on the RCRAInfo Handler ID
#                      (PGM_SYS_ID where PGM_SYS_ACRNM == "RCRAINFO"); NA when no
#                      RCRAINFO link exists.
#   YEAR, MONTH        Panel index (2015-2023 x 1-12), the calendar year and
#                      month of DETERMINED_DATE for the row's violations.
#
#   Handler attributes (from the handler snapshot columns on the violation
#   records; the value on the handler's most recently determined violation is
#   used and repeated across all 108 months):
#     CE_ACTIVITY_STATE  <- HANDLER_ACTIVITY_LOCATION
#     CE_LOCATION_STATE  <- STATE
#     CE_EPA_REGION      <- REGION
#     CE_LAND_TYPE       <- LAND_TYPE (last non-missing)
#
#   Violation fields (month level; empty when the month has no violation; 68.3%
#   of active months hold more than one violation, a far denser cell than in the
#   evaluation or enforcement panels, so multi-valued string fields carry the
#   distinct values in determined-date order, joined with ";"):
#     CE_VIOL_STATE      <- VIOL_ACTIVITY_LOCATION, the state whose agency
#                           regulates the activity that was violated.
#     CE_VIOL_RESP_AGENCY<- RESPONSIBLE_AGENCY, the distinct agencies responsible
#                           for the violation (S state, E EPA, and a handful of
#                           other codes); blank on the 0.5% of window violations
#                           that record none.
#     CE_CITATION        <- CITATION, the distinct regulatory citations, each
#                           prefixed with its own CITATION_OWNER as OWNER-CITATION
#                           (e.g. HQ-262.34(a), OH-279-54(C)(1)), so a state code
#                           and a federal code that read alike stay distinct.
#                           Blank on the 21.9% of window violations that carry no
#                           citation row.
#     CE_CITATION_TYPE   <- CITATION_TYPE, the distinct citation-origin codes in
#                           the month (sorted): FR federal regulation, SR state
#                           regulation, SS state statute, FS federal statute, PC
#                           permit condition, OC other citation.
#     CE_CITATION_NUM    Count of distinct OWNER-CITATION pairs in the month.
#     CE_RTC_DATE        <- ACTUAL_RTC_DATE, the distinct dates on which the
#                           month's violations returned to compliance (96.9% of
#                           window violations have one), in determined-date order
#                           and written as YYYYMMDD. Two violations that closed on
#                           the same day collapse to a single entry, so the number
#                           of entries is not the number of violations that
#                           returned; that is CE_TOTAL_VIOL minus CE_TOTAL_OPEN.
#                           The return can fall in a later month than the row, and
#                           in 2024-2026 for violations determined late in the
#                           window, so the field describes violations determined in
#                           the month rather than compliance restored during it.
#
#   Counts and indicators (0 on months with no violation; CE_ANY_* = 1 when the
#   matching count is > 0, else 0):
#     CE_ANY_VIOL,       CE_TOTAL_VIOL       all violations determined in the month
#     CE_ANY_STATE_VIOL, CE_TOTAL_STATE_VIOL VIOL_DETERMINED_BY_AGENCY == "S"
#     CE_ANY_FED_VIOL,   CE_TOTAL_FED_VIOL   VIOL_DETERMINED_BY_AGENCY == "E"
#     CE_ANY_OPEN,       CE_TOTAL_OPEN       violations with no ACTUAL_RTC_DATE,
#                                            still open as of the data pull. The
#                                            complement, violations that returned
#                                            to compliance, is CE_TOTAL_VIOL minus
#                                            CE_TOTAL_OPEN.
#     CE_VIOL_EVAL_NUM   Count of distinct evaluations linked to the month's
#                        violations, on the evaluation key the evaluation panel
#                        uses. A violation can be linked to several evaluations,
#                        so this is not a count of the month's evaluations.
#     CE_VIOL_ENF_NUM    Count of distinct enforcement actions linked to the
#                        month's violations, on the enforcement key the
#                        enforcement panel uses. The action can be dated in a
#                        later month than the row.
#
#   Violation-type counts and indicators (0 on months with no violation). Each
#   violation carries exactly one VIOL_TYPE, so the seven CE_TOTAL_* counts sum
#   to CE_TOTAL_VIOL. The six typed codes are the most common in the window and
#   the cut is taken at the largest break in the frequency ranking, between
#   262.D and 262.B; the percentages below are the share of the 52,155 active
#   facility-months in which the code appears:
#     CE_ANY_262A,  CE_TOTAL_262A  262.A Generators - General (38.0%)
#     CE_ANY_262C,  CE_TOTAL_262C  262.C Generators - Pre-transport (32.4%)
#     CE_ANY_XXS,   CE_TOTAL_XXS   XXS State Statute or Regulation (26.9%). This
#                                  is the state catch-all rather than an area of
#                                  the CFR, so it records that a state wrote the
#                                  violation against its own rule and says
#                                  nothing about which requirement was broken.
#     CE_ANY_273B,  CE_TOTAL_273B  273.B Universal Waste - Small Quantity
#                                  Handlers (20.4%)
#     CE_ANY_279C,  CE_TOTAL_279C  279.C Used Oil - Generators (16.3%)
#     CE_ANY_262D,  CE_TOTAL_262D  262.D Generators - Records/Reporting (14.7%)
#     CE_ANY_OTHER, CE_TOTAL_OTHER every other code, 105 of them, together 27.4%
#                                  of the 206,708 window violations. The largest are
#                                  262.B Generators - Manifest (8.9% of active
#                                  months), 265.I TSD IS-Container Use and
#                                  Management (8.0%), and 268.A LDR - General
#                                  (6.1%); by violation count they are 265.I with
#                                  5,482, 262.B with 5,278, and 262.M with 4,554.
#                                  The panel does not carry the codes
#                                  themselves, so which of the 106 fired in a
#                                  month is only recoverable from CE_MASTER.
#
#   One violation-type code is recoded before any of these columns are built.
#   262.34(a), which the RCRAInfo Nationally-Defined Values page for CM&E
#   Violation Type does not list, is a citation typed into the code field on 26
#   window violations whose records carry "Generators - General", the description
#   of 262.A, and it is read as that code. The only other unlisted codes, 257.90E
#   and 257.91, are coal combustion residuals under 40 CFR 257, outside Subtitle
#   C, and their three records are determined on 2024-05-01, 2024-08-05, and
#   2025-03-03, all after the window closes. Every remaining code in the window is
#   nationally defined.
#
# Violation determining agency is "S" or "E" for every violation in the window,
# so the state/federal split is exhaustive; any other agency code, if it ever
# appears, counts toward neither state nor federal. RESPONSIBLE_AGENCY, the
# agency that owns the violation afterwards, is a separate field and does carry
# a few other codes, so it is kept as a string rather than split into counts.
#
# Requires: tidyverse (incl. lubridate)
# =============================================================================

# Shared panel helpers: join_distinct(), last_known(), read_frs_links(),
# write_panel(). Loads tidyverse.
source("code/modules/03_panels/rcrainfo/00_panel_functions.R")

# Inputs, output, and the panel year range.
ce_file  <- "output/modular_master_files/CE_MASTER.csv"
frs_file <- "data/frs/FRS_PROGRAM_LINKS.csv"
out_file <- "output/panels/CE_PANEL_2015_2023/VIOL_PANEL_2015_2023.csv"
years    <- 2015L:2023L

# Violation types with their own count column; every other code rolls into
# CE_TOTAL_OTHER. These are the six most common codes in the window, and the cut
# is taken at the largest break in the frequency ranking: 262.D appears in 14.7%
# of active facility-months and the next code, 262.B, in 8.9%, a 40% drop, where
# no step above it falls by more than 25%. The six cover 150,157 of the 206,708
# window violations (72.6%); OTHER carries the remaining 105 codes and 27.4%.
typed <- c("262.A", "262.C", "XXS", "273.B", "279.C", "262.D")

# Column suffix for each typed code, since a column name cannot carry the dot.
typed_tag <- str_remove(typed, "\\.")   # 262.A -> 262A, XXS -> XXS

# The one violation-type code in the window that the RCRAInfo Nationally-Defined
# Values page for CM&E Violation Type does not list. It is a citation, 40 CFR
# 262.34(a), typed into the code field on 26 window violations, and the records
# carry "Generators - General", the description of 262.A, so they are recoded to
# that code. The only other unlisted codes, 257.90E and 257.91, are coal
# combustion residuals under 40 CFR 257, outside Subtitle C, and all three of
# their records are determined after the window closes (2024-05-01, 2024-08-05,
# and 2025-03-03).
recode_type <- c("262.34(a)" = "262.A")

# -- 1. CE_MASTER -> one row per violation, month-assigned ----------------------
# RCRAInfo violation key: the four columns that uniquely identify a violation.
key <- c("HANDLER_ID", "VIOL_ACTIVITY_LOCATION", "VIOL_SEQ",
         "VIOL_DETERMINED_BY_AGENCY")

# The fields that vary within the violation key and so must be aggregated over
# all of its rows rather than read off the collapsed row.
raw <- read_csv(ce_file, col_types = cols(.default = "c"), show_col_types = FALSE,
                # Pull only the columns needed for the panel; the master file is
                # wide, so restricting here saves memory.
                col_select = c(all_of(key), VIOL_TYPE,
                               DETERMINED_DATE, RESPONSIBLE_AGENCY,
                               ACTUAL_RTC_DATE,
                               CITATION_OWNER, CITATION, CITATION_TYPE,
                               EVAL_ACTIVITY_LOCATION, EVAL_IDENTIFIER,
                               EVAL_START_DATE, EVAL_AGENCY,
                               ENF_ACTIVITY_LOCATION, ENF_IDENTIFIER,
                               ENF_ACTION_DATE, ENF_AGENCY,
                               HANDLER_ACTIVITY_LOCATION, STATE, REGION, LAND_TYPE)) |>
  # Drop the rows that carry no violation at all (evaluations that found none).
  filter(!(is.na(VIOL_SEQ) & is.na(VIOL_TYPE) & is.na(DETERMINED_DATE))) |>
  # Assign the month from the determination date and keep the panel window.
  mutate(determined = ymd(DETERMINED_DATE, quiet = TRUE)) |>
  filter(!is.na(determined), year(determined) %in% years) |>
  mutate(YEAR  = year(determined),
         MONTH = month(determined),
         # Recode the one unlisted code to the defined code its own description
         # names, before anything reads the type.
         VIOL_TYPE = coalesce(unname(recode_type[VIOL_TYPE]), VIOL_TYPE),
         # A citation is only unique within the agency that wrote it, so it
         # carries its owner as an "OWNER-CITATION" prefix (e.g. HQ-262.34(a)).
         CITATION_ID = if_else(!is.na(CITATION) & CITATION != "",
                               paste(CITATION_OWNER, CITATION, sep = "-"),
                               NA_character_),
         # Composite keys for the linked evaluation and enforcement action, so
         # the counts below use the same identity as the other two panels.
         EVAL_KEY = paste(EVAL_ACTIVITY_LOCATION, EVAL_IDENTIFIER,
                          EVAL_START_DATE, EVAL_AGENCY),
         ENF_KEY  = if_else(is.na(ENF_IDENTIFIER) & is.na(ENF_ACTION_DATE),
                            NA_character_,
                            paste(ENF_ACTIVITY_LOCATION, ENF_IDENTIFIER,
                                  ENF_ACTION_DATE, ENF_AGENCY)))

# Collapse the master's fanout down to one row per violation. The violation's own
# attributes are constant within the key, so taking them from the first row is
# safe (see the header); the fields that do vary within the key are aggregated
# from the uncollapsed rows in step 2 instead.
viols <- raw |>
  distinct(across(all_of(key)), .keep_all = TRUE) |>
  # Return-to-compliance date, parsed once so agg can split returned from open.
  mutate(rtc = ymd(ACTUAL_RTC_DATE, quiet = TRUE))

# Sorted handler list defines the panel row space (used by expand_grid() below).
ids <- sort(unique(viols$HANDLER_ID))

# -- 2. Facility-month aggregates ----------------------------------------------
# Collapse to one row per (handler, year, month) with every violation determined
# in the month rolled into a set of string, count, and indicator fields.
agg <- viols |>
  # Sort by determination date so join_distinct() emits chronological order.
  arrange(HANDLER_ID, determined) |>
  group_by(HANDLER_ID, YEAR, MONTH) |>
  summarise(
    # Distinct regulating states on the month's violations.
    CE_VIOL_STATE       = join_distinct(VIOL_ACTIVITY_LOCATION),
    CE_VIOL_RESP_AGENCY = join_distinct(RESPONSIBLE_AGENCY),
    # Distinct return-to-compliance dates, in determined-date order. Two
    # violations that closed on the same day collapse to one entry, so the entry
    # count is not the number of violations that returned to compliance; that is
    # CE_TOTAL_VIOL minus CE_TOTAL_OPEN.
    CE_RTC_DATE         = join_distinct(ACTUAL_RTC_DATE),
    # Counts: total, the exhaustive state (S) / federal (E) split, and the
    # violations still open.
    CE_TOTAL_VIOL       = n(),
    CE_TOTAL_STATE_VIOL = sum(VIOL_DETERMINED_BY_AGENCY == "S", na.rm = TRUE),
    CE_TOTAL_FED_VIOL   = sum(VIOL_DETERMINED_BY_AGENCY == "E", na.rm = TRUE),
    CE_TOTAL_OPEN       = sum(is.na(rtc)),
    # Per-type counts for the six typed codes, and OTHER for every other code.
    # Each violation carries one type, so the seven counts sum to CE_TOTAL_VIOL.
    CE_TOTAL_262A       = sum(VIOL_TYPE == "262.A", na.rm = TRUE),
    CE_TOTAL_262C       = sum(VIOL_TYPE == "262.C", na.rm = TRUE),
    CE_TOTAL_XXS        = sum(VIOL_TYPE == "XXS",   na.rm = TRUE),
    CE_TOTAL_273B       = sum(VIOL_TYPE == "273.B", na.rm = TRUE),
    CE_TOTAL_279C       = sum(VIOL_TYPE == "279.C", na.rm = TRUE),
    CE_TOTAL_262D       = sum(VIOL_TYPE == "262.D", na.rm = TRUE),
    CE_TOTAL_OTHER      = sum(!VIOL_TYPE %in% typed, na.rm = TRUE),
    .groups = "drop")

# The fields that fan a violation across several master rows are aggregated from
# the uncollapsed rows instead, since every one of them is a distinct-value or
# distinct-count field, where repeating a violation's rows changes nothing.
links <- raw |>
  arrange(HANDLER_ID, determined) |>
  group_by(HANDLER_ID, YEAR, MONTH) |>
  summarise(
    # Owner-prefixed citations and their origin codes.
    CE_CITATION        = join_distinct(CITATION_ID),
    CE_CITATION_TYPE   = paste(sort(unique(CITATION_TYPE[!is.na(CITATION_TYPE)])),
                               collapse = ";"),
    CE_CITATION_NUM    = n_distinct(CITATION_ID[!is.na(CITATION_ID)]),
    # Distinct evaluations and enforcement actions linked to the month's
    # violations, on the same keys the other two panels use.
    CE_VIOL_EVAL_NUM   = n_distinct(EVAL_KEY[!is.na(EVAL_KEY)]),
    CE_VIOL_ENF_NUM    = n_distinct(ENF_KEY[!is.na(ENF_KEY)]),
    .groups = "drop")

agg <- left_join(agg, links, by = c("HANDLER_ID", "YEAR", "MONTH"))

# -- 3. Handler attributes (most recent violation's snapshot) -------------------
# Repeat these attributes across all 108 months for the handler, using the value
# on the handler's most recently determined violation.
attrs <- viols |>
  arrange(HANDLER_ID, determined) |>
  group_by(HANDLER_ID) |>
  summarise(CE_ACTIVITY_STATE = last_known(HANDLER_ACTIVITY_LOCATION),
            CE_LOCATION_STATE = last_known(STATE),
            CE_EPA_REGION     = last_known(REGION),
            CE_LAND_TYPE      = last_known(LAND_TYPE),
            .groups = "drop")

# -- 4. FRS: Facility Registry Service ID ---------------------------------------
# Same link as the other panels (see read_frs_links() in 00_panel_functions.R).
frs <- read_frs_links(ids, frs_file)

# -- 5. Balanced grid, assemble, write ------------------------------------------
# expand_grid() emits rows already sorted HANDLER_ID x YEAR x MONTH and the left
# joins preserve that order, so no final arrange over the 4.2M rows is needed.
# Count columns to zero-fill on months with no violation.
count_cols <- c("CE_CITATION_NUM",
                "CE_TOTAL_VIOL", "CE_TOTAL_STATE_VIOL", "CE_TOTAL_FED_VIOL",
                "CE_TOTAL_OPEN",
                "CE_VIOL_EVAL_NUM", "CE_VIOL_ENF_NUM",
                paste0("CE_TOTAL_", typed_tag), "CE_TOTAL_OTHER")

out <- expand_grid(HANDLER_ID = ids, YEAR = years, MONTH = 1:12) |>
  # Attach the identifier and the constant handler attributes on ID alone.
  left_join(frs,   by = "HANDLER_ID") |>
  left_join(attrs, by = "HANDLER_ID") |>
  # Attach per-month aggregates; months with no violation get NA columns.
  left_join(agg,   by = c("HANDLER_ID", "YEAR", "MONTH")) |>
  # Replace NAs in the count columns with 0, then derive the CE_ANY_* flags.
  mutate(across(all_of(count_cols), \(x) replace_na(x, 0L)),
         CE_ANY_VIOL       = as.integer(CE_TOTAL_VIOL       > 0),
         CE_ANY_STATE_VIOL = as.integer(CE_TOTAL_STATE_VIOL > 0),
         CE_ANY_FED_VIOL   = as.integer(CE_TOTAL_FED_VIOL   > 0),
         CE_ANY_OPEN       = as.integer(CE_TOTAL_OPEN       > 0),
         CE_ANY_262A       = as.integer(CE_TOTAL_262A       > 0),
         CE_ANY_262C       = as.integer(CE_TOTAL_262C       > 0),
         CE_ANY_XXS        = as.integer(CE_TOTAL_XXS        > 0),
         CE_ANY_273B       = as.integer(CE_TOTAL_273B       > 0),
         CE_ANY_279C       = as.integer(CE_TOTAL_279C       > 0),
         CE_ANY_262D       = as.integer(CE_TOTAL_262D       > 0),
         CE_ANY_OTHER      = as.integer(CE_TOTAL_OTHER      > 0)) |>
  # Final panel column order.
  select(HANDLER_ID, FRS_ID, YEAR, MONTH,
         CE_ACTIVITY_STATE, CE_LOCATION_STATE, CE_EPA_REGION, CE_LAND_TYPE,
         CE_VIOL_STATE,
         CE_ANY_VIOL,       CE_TOTAL_VIOL,
         CE_ANY_STATE_VIOL, CE_TOTAL_STATE_VIOL,
         CE_ANY_FED_VIOL,   CE_TOTAL_FED_VIOL,
         CE_ANY_OPEN,       CE_TOTAL_OPEN,
         CE_ANY_262A,       CE_TOTAL_262A,
         CE_ANY_262C,       CE_TOTAL_262C,
         CE_ANY_XXS,        CE_TOTAL_XXS,
         CE_ANY_273B,       CE_TOTAL_273B,
         CE_ANY_279C,       CE_TOTAL_279C,
         CE_ANY_262D,       CE_TOTAL_262D,
         CE_ANY_OTHER,      CE_TOTAL_OTHER,
         CE_RTC_DATE, CE_VIOL_RESP_AGENCY,
         CE_CITATION_NUM, CE_CITATION, CE_CITATION_TYPE,
         CE_VIOL_EVAL_NUM, CE_VIOL_ENF_NUM)

# write_panel() writes the CSV plus an .rds twin: plain CSV stores no column
# types, so read_csv() re-guesses them and mistypes the columns that only look
# numeric (CE_RTC_DATE re-reads as a double, which turns every multi-date cell
# into NA, and FRS_ID stops being an identifier); the .rds copy preserves every
# column's type exactly.
write_panel(out, out_file, rds = TRUE)
