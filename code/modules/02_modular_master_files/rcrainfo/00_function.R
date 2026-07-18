# =============================================================================
# FILE:     00_function.R
# PURPOSE:  Shared functions behind the module master files. Each master script
#           in this folder sources this file; running it on its own only
#           defines the functions.
# INPUTS:   none (sourced by the master scripts 01-07 in this folder)
# OUTPUTS:  none of its own; defines read_module(), recode_pre_date_unknown(),
#           recode_pre_cycle_unknown(), and convert_indicators()
# AUTHOR:   Jason Ye
# CREATED:  2026-07-17
# UPDATED:  2026-07-17
# =============================================================================
#
# Three concerns are shared by every master script and live here.
#
# 1. Reading. read_module() reads a raw RCRAInfo CSV with every column as
#    character, so zero-padded identifiers and yyyymmdd date stamps survive
#    verbatim, and replaces the spaces in the shipped column names with
#    underscores.
#
# 2. Unknown recoding. The ECHO RCRAInfo download summary documents that for
#    several Handler activity flags an "N" recorded before the date the flag
#    entered the notification form does not distinguish "No" from "Unknown".
#    The two recode helpers turn those undistinguishable entries into an
#    explicit "U" (unknown) code so the master files never present them as
#    real negatives:
#      recode_pre_date_unknown()   "N" -> "U" on records whose RECEIVE_DATE
#                                  (yyyymmdd) predates a cutoff, optionally
#                                  restricted to a set of SOURCE_TYPE codes
#      recode_pre_cycle_unknown()  blank -> "U" on records whose REPORT_CYCLE
#                                  predates a cutoff cycle
#    The rules themselves (which fields, which cutoffs) are declared in
#    01_hd_master.R, the one master they apply to.
#
# 3. Indicator conversion. The raw files code binary indicators as Y/N. The
#    master files carry them as 1/0 instead, the usual coding of an economic
#    research dataset. convert_indicators() maps Y -> 1 and N -> 0 on the
#    declared indicator columns and then retypes each: a column whose values
#    are only 1/0 becomes an integer column, while a column that also carries
#    "U" (unknown, from the recodes above or shipped in the raw data) must
#    stay character, holding "1"/"0"/"U".
#
# Requires: tidyverse
# =============================================================================

library(tidyverse)

# Read one raw module CSV entirely as character, with underscore column names.
read_module <- function(dir, file) {
  df <- read_csv(file.path(dir, file),
                 col_types = cols(.default = "c"), show_col_types = FALSE)
  names(df) <- gsub(" ", "_", names(df))
  df
}

# "N" -> "U" on the given columns for records whose RECEIVE_DATE predates the
# cutoff (an integer yyyymmdd), optionally restricted to a set of SOURCE_TYPE
# codes. RECEIVE_DATE is always an eight-digit yyyymmdd stamp in the raw data,
# so an integer comparison is exact.
recode_pre_date_unknown <- function(df, cols, cutoff, source_types = NULL) {
  rd  <- suppressWarnings(as.integer(df$RECEIVE_DATE))
  hit <- !is.na(rd) & rd < cutoff
  if (!is.null(source_types)) hit <- hit & df$SOURCE_TYPE %in% source_types
  mutate(df, across(all_of(cols),
                    \(x) if_else(hit & !is.na(x) & x == "N", "U", x)))
}

# blank -> "U" on the given columns for records whose REPORT_CYCLE predates the
# cutoff cycle. Records with no REPORT_CYCLE at all are left untouched: the
# rule speaks only about records that carry a cycle.
recode_pre_cycle_unknown <- function(df, cols, cutoff) {
  rc  <- suppressWarnings(as.integer(df$REPORT_CYCLE))
  hit <- !is.na(rc) & rc < cutoff
  mutate(df, across(all_of(cols),
                    \(x) if_else(hit & (is.na(x) | x == ""), "U", x)))
}

# Y -> "1", N -> "0" on the declared indicator columns, then retype: pure 1/0
# columns become integer; columns that also carry "U" stay character. Any
# value outside Y/N/U in a declared column is a coding surprise worth a hard
# stop rather than a silent pass-through.
convert_indicators <- function(df, cols) {
  bad <- keep(cols, \(cl) !all(df[[cl]] %in% c("Y", "N", "U", NA)))
  if (length(bad)) stop("Non-Y/N/U values in indicator column(s): ",
                        paste(bad, collapse = ", "))
  df |>
    mutate(across(all_of(cols),
                  \(x) case_match(x, "Y" ~ "1", "N" ~ "0", .default = x))) |>
    mutate(across(all_of(cols),
                  \(x) if (all(x %in% c("1", "0", NA))) as.integer(x) else x))
}
