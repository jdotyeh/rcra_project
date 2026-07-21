# =============================================================================
# FILE:     05_panel_viol_2015_2023_citations.R
# PURPOSE:  Rank the regulatory citations carried by the violation panel, one
#           row per distinct citation, so the most frequent ones are visible
#           without splitting the panel's joined field by hand.
# INPUTS:   output/panels/CE_PANEL_2015_2023/VIOL_PANEL_2015_2023.rds
# OUTPUTS:  output/panels/summary/viol_citation_frequency.csv
# AUTHOR:   Jason Ye
# CREATED:  2026-07-21
# UPDATED:  2026-07-21
# =============================================================================
#
# Frequency table of the citations in VIOL_PANEL_2015_2023. The panel carries
# them in CE_CITATION, where a facility-month holding several citations joins
# them with ";", so the field has to be split before anything is counted. Each
# citation is counted on its own here: a month whose field reads
# "HQ-262.34(a);OH-279-54(C)(1)" counts once toward each of the two, never once
# toward the pair.
#
# A citation keeps the owner prefix the panel gives it, OWNER-CITATION, because
# a citation is only unique within the agency that wrote it and a state code and
# a federal code can read alike. The owner and the code are also split back out
# into their own columns so the table can be grouped either way.
#
# Columns of the written table, sorted by FACILITY_MONTHS descending and by the
# citation for ties:
#   RANK              Position in that ordering, so the breaks in the ranking
#                     can be named directly.
#   CITATION          The panel's OWNER-CITATION value, e.g. HQ-262.34(a).
#   CITATION_OWNER    The owner prefix alone, e.g. HQ or OH.
#   CITATION_CODE     The citation alone, without the owner prefix.
#   FACILITY_MONTHS   Facility-months whose CE_CITATION holds the citation.
#   PCT_ACTIVE_MONTHS FACILITY_MONTHS as a percentage of the facility-months
#                     that hold at least one violation, the same denominator the
#                     violation panel's header uses for its violation-type
#                     shares, so the two rankings are read on one scale.
#   FACILITIES        Distinct handlers that carry the citation in any month.
#   CUM_PCT_MENTIONS  Running share of all citation mentions down the ranking,
#                     which is how far the table has to be read to cover a given
#                     part of the citations in the window.
#
# The panel deduplicates citations within a facility-month, so a citation
# written on two violations in the same month is one mention here, and
# FACILITY_MONTHS is a count of months rather than of violations.
#
# Requires: tidyverse
# =============================================================================

# Only the tidyverse is needed; this script reads a finished panel and writes a
# table of its own, so it uses none of the shared panel helpers.
library(tidyverse)

# The panel to read and the summary file to write. The .rds twin is read rather
# than the CSV because a plain CSV re-read re-guesses the column types and
# mistypes the panel's sparse columns.
panel_file <- "output/panels/CE_PANEL_2015_2023/VIOL_PANEL_2015_2023.rds"
out_file   <- "output/panels/summary/viol_citation_frequency.csv"

viol <- read_rds(panel_file)

# Facility-months holding at least one violation. The panel is balanced over all
# 108 months, so most of its rows are empty months that belong in no denominator.
active   <- filter(viol, CE_ANY_VIOL == 1L)
n_active <- nrow(active)

# Split the joined field into one row per (facility-month, citation). The panel
# already deduplicates within the month, so distinct() only guards against a
# repeat surviving the split.
cites <- active |>
  filter(!is.na(CE_CITATION), CE_CITATION != "") |>
  select(HANDLER_ID, YEAR, MONTH, CE_CITATION) |>
  mutate(CITATION = str_split(CE_CITATION, ";")) |>
  unnest(CITATION) |>
  mutate(CITATION = str_squish(CITATION)) |>
  filter(CITATION != "") |>
  distinct(HANDLER_ID, YEAR, MONTH, CITATION)

# Count each citation over the facility-months and the handlers that carry it,
# then rank. The owner prefix runs to the first "-", and everything after it is
# the citation the owner wrote, which itself often contains further hyphens.
freq <- cites |>
  group_by(CITATION) |>
  summarise(FACILITY_MONTHS = n(),
            FACILITIES      = n_distinct(HANDLER_ID),
            .groups = "drop") |>
  arrange(desc(FACILITY_MONTHS), CITATION) |>
  mutate(RANK              = row_number(),
         CITATION_OWNER    = str_extract(CITATION, "^[^-]+"),
         CITATION_CODE     = str_remove(CITATION, "^[^-]+-"),
         PCT_ACTIVE_MONTHS = round(100 * FACILITY_MONTHS / n_active, 2),
         CUM_PCT_MENTIONS  = round(100 * cumsum(FACILITY_MONTHS) /
                                     sum(FACILITY_MONTHS), 2)) |>
  select(RANK, CITATION, CITATION_OWNER, CITATION_CODE,
         FACILITY_MONTHS, PCT_ACTIVE_MONTHS, FACILITIES, CUM_PCT_MENTIONS)

# Report the scale of the table and its head, so a run says what it found
# without the file having to be opened.
message("Distinct citations: ", nrow(freq),
        " over ", n_active, " active facility-months")
print(head(freq, 25))

# Write the whole ranking; the summary folder is shared with the panel summaries.
dir.create(dirname(out_file), showWarnings = FALSE, recursive = TRUE)
write_csv(freq, out_file, na = "")
