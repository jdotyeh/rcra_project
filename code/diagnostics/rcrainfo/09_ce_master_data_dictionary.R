# =============================================================================
# 09_ce_master_data_dictionary.R
#
# Data dictionary for the CME master file (output/diagnostics/cme_master.csv,
# built by code/diagnostics/rcrainfo/08_ce_master_prototype.R), scraped live
# from the EPA RCRAInfo Public Data Element Dictionary so a re-run picks up
# any EPA revision:
#
#   DED-CMEReportingTables.htm -> CE_REPORTING elements
#   DED-CMEModule.htm          -> CE_CITATION elements
#
# Element rows are matched to master-file columns by position: the public
# DED lists elements in CSV column order, except the three *_LAST_CHANGE
# columns, which the DED omits (described locally below). Guards stop the
# script if EPA adds/removes elements so the mapping never drifts silently.
#
# Every "see nationally-defined values" page linked from the DED is also
# fetched and written as its own markdown file in a folder next to the
# dictionary; the dictionary links to those files.
#
# Output:
#   output/diagnostics/data_dictionary/cme_master_data_dictionary.md
#   output/diagnostics/data_dictionary/nationally_defined_values/<NDV page>.md
#
# Requires: tidyverse, rvest
# =============================================================================

library(tidyverse)
library(rvest)

help_root <- "https://rcrainfo.epa.gov/rcrainfo-help/application/publicHelp"
ded_urls <- c(
  CE_REPORTING = file.path(help_root, "DataElementDictionary/DED-CMEReportingTables.htm"),
  CE_CITATION  = file.path(help_root, "DataElementDictionary/DED-CMEModule.htm")
)

out_dir   <- "output/diagnostics/data_dictionary"
ndv_dir   <- file.path(out_dir, "nationally_defined_values")
dict_file <- file.path(out_dir, "cme_master_data_dictionary.md")
dir.create(ndv_dir, recursive = TRUE, showWarnings = FALSE)

md_escape <- function(x) str_squish(str_replace_all(x, "\\|", "\\\\|"))

# ---- Scrape the two DED pages -----------------------------------------------
# Each page: first table.DED = element table (header row, then one row per
# element: English Name | Description). NDV links sit inside the description.
parse_ded <- function(url) {
  rows <- read_html(url) |>
    html_element("table.DED") |>
    html_elements("tr")
  rows <- rows[-1]  # header row
  map_dfr(rows, function(r) {
    cells <- html_elements(r, "td")
    ndv <- html_elements(cells[[2]], "a") |> html_attr("href")
    ndv <- ndv[str_detect(ndv, "NationallyDefinedValues")][1]
    tibble(
      english     = str_squish(html_text2(cells[[1]])),
      description = html_text2(cells[[2]]) |>
        str_remove_all("\\[\\s*see nationally-defined values\\s*\\]") |>
        md_escape(),
      ndv_href    = ndv
    )
  })
}

rep_el <- parse_ded(ded_urls["CE_REPORTING"])
cit_el <- parse_ded(ded_urls["CE_CITATION"])

# ---- Match elements to master-file columns ----------------------------------
# CE_REPORTING csv header, minus the three last-change columns the DED skips,
# is the DED element order.
csv_header <- function(file) {
  h <- read_csv(file, n_max = 0, show_col_types = FALSE)
  gsub(" ", "_", names(h))
}

last_change <- c("EVAL_LAST_CHANGE", "VIOL_LAST_CHANGE", "ENF_LAST_CHANGE")
rep_cols <- setdiff(csv_header("data/rcrainfo/ce/CE_REPORTING.csv"),
                    last_change)
stopifnot(length(rep_cols) == nrow(rep_el))

cit_cols <- csv_header("data/rcrainfo/ce/CE_CITATION.csv")
cit_cols[cit_cols == "VIOL_OWNER"] <- "VIOL_TYPE_OWNER"
stopifnot(length(cit_cols) == nrow(cit_el))

elements <- bind_rows(
  rep_el |> mutate(column = rep_cols, source = "CE_REPORTING"),
  # only the five columns the citation file adds to the master
  cit_el |> mutate(column = cit_cols, source = "CE_CITATION") |>
    filter(column %in% c("CITATION_SEQ", "VIOL_TYPE_OWNER", "CITATION_OWNER",
                         "CITATION", "CITATION_TYPE")),
  tibble(
    column      = last_change,
    source      = "CE_REPORTING",
    english     = c("Evaluation Last Change", "Violation Last Change",
                    "Enforcement Last Change"),
    description = paste("Date the", c("evaluation", "violation", "enforcement"),
                        "record was last changed in RCRAInfo.",
                        "Not documented in the public DED."),
    ndv_href    = NA_character_
  )
)

# ---- Fetch every linked nationally-defined-values page ----------------------
ndv_hrefs <- unique(na.omit(elements$ndv_href))

ndv_to_md <- function(href) {
  url  <- file.path(help_root, str_remove(href, "^\\.\\./"))
  slug <- str_remove(basename(href), "\\.htm$")
  pg   <- read_html(url)
  title <- html_elements(pg, "h1") |> html_text2() |> keep(nzchar) |> last()
  rows <- pg |> html_element("table.NDV") |> html_elements("tr")
  cells <- map(rows, \(r) html_elements(r, "td") |> html_text2() |> md_escape())
  md_row <- function(x) paste0("| ", paste(x, collapse = " | "), " |")
  lines <- c(
    paste("#", title),
    "",
    paste0("Source: <", url, ">  "),
    paste("Retrieved:", Sys.Date()),
    "",
    md_row(cells[[1]]),
    md_row(rep("---", length(cells[[1]]))),
    map_chr(cells[-1], md_row)
  )
  writeLines(lines, file.path(ndv_dir, paste0(slug, ".md")))
  slug
}

ndv_slugs <- set_names(map_chr(ndv_hrefs, ndv_to_md), ndv_hrefs)
elements <- elements |>
  mutate(ndv = if_else(
    is.na(ndv_href), "—",
    paste0("[", ndv_slugs[ndv_href], "](nationally_defined_values/",
           ndv_slugs[ndv_href], ".md)")
  ))

# ---- Write the master dictionary, sectioned like the master file ------------
sections <- list(
  "Basic information" = c(
    "HANDLER_ID", "EVAL_IDENTIFIER", "VIOL_SEQ", "ENF_IDENTIFIER",
    "REQUEST_SEQ", "CITATION_SEQ", "CAFO_SEQ", "SEP_SEQ"),
  "Handler snapshot" = c(
    "HANDLER_NAME", "HANDLER_ACTIVITY_LOCATION", "REGION", "STATE",
    "LAND_TYPE"),
  "Evaluation information" = c(
    "EVAL_ACTIVITY_LOCATION", "EVAL_TYPE", "EVAL_TYPE_DESC",
    "FOCUS_AREA", "FOCUS_AREA_DESC", "EVAL_START_DATE", "EVAL_AGENCY",
    "FOUND_VIOLATION", "CITIZEN_COMPLAINT", "MULTIMEDIA_INSPECTION",
    "SAMPLING", "NOT_SUBTITLE_C", "NOC_DATE", "EVAL_RESPONSIBLE_PERSON",
    "EVAL_SUBORGANIZATION", "EVAL_LAST_CHANGE"),
  "3007 request information" = c(
    "DATE_OF_REQUEST", "DATE_RESPONSE_RECEIVED", "REQUEST_AGENCY",
    "REQUEST_ACTIVITY_LOCATION"),
  "Violation information" = c(
    "VIOL_ACTIVITY_LOCATION", "VIOL_TYPE_OWNER", "VIOL_TYPE",
    "VIOL_SHORT_DESC", "DETERMINED_DATE", "VIOL_DETERMINED_BY_AGENCY",
    "RESPONSIBLE_AGENCY", "SCHEDULED_COMPLIANCE_DATE", "ACTUAL_RTC_DATE",
    "RTC_QUALIFIER", "CITATION_OWNER", "CITATION", "CITATION_TYPE",
    "FORMER_CITATION", "VIOL_LAST_CHANGE"),
  "Enforcement information" = c(
    "ENF_ACTIVITY_LOCATION", "ENF_TYPE", "ENF_TYPE_DESC", "ENF_ACTION_DATE",
    "ENF_AGENCY", "DOCKET_NUMBER", "ATTORNEY", "ENF_RESPONSIBLE_PERSON",
    "ENF_SUBORGANIZATION", "CA_COMPONENT", "FA_REQUIREMENT",
    "APPEAL_INITIATED_DATE", "APPEAL_RESOLVED_DATE", "DISPOSITION_STATUS",
    "DISPOSITION_STATUS_DESC", "DISPOSITION_STATUS_DATE", "RESPONDENT_NAME",
    "LEAD_AGENCY", "ENF_LAST_CHANGE"),
  "Penalty & SEP information" = c(
    "PROPOSED_AMOUNT", "FINAL_MONETARY_AMOUNT", "PAID_AMOUNT", "FINAL_COUNT",
    "FINAL_AMOUNT", "SEP_TYPE", "SEP_TYPE_DESC", "EXPENDITURE_AMOUNT",
    "SCHEDULED_COMPLETION_DATE", "ACTUAL_COMPLETION_DATE",
    "SEP_DEFAULTED_DATE")
)
stopifnot(sort(unlist(sections)) == sort(elements$column))

section_md <- function(title, cols) {
  rows <- elements |> slice(match(cols, column))
  c(paste("##", title),
    "",
    "| Column | Source table | EPA English name | Description | Nationally-defined values |",
    "| --- | --- | --- | --- | --- |",
    pmap_chr(rows, \(column, source, english, description, ndv, ...)
      paste("|", paste(c(paste0("`", column, "`"), source, english,
                         description, ndv), collapse = " | "), "|")),
    "")
}

dictionary <- c(
  "# CME Master File Data Dictionary",
  "",
  "Column-level documentation for `output/diagnostics/cme_master.csv`",
  "(built by `code/diagnostics/rcrainfo/08_ce_master_prototype.R`; one row",
  "per evaluation x violation x enforcement x SEP x citation combination).",
  "",
  "Descriptions are scraped from the EPA RCRAInfo Public Data Element",
  "Dictionary; regenerate this file with",
  "`code/diagnostics/rcrainfo/09_ce_master_data_dictionary.R`",
  "to pick up EPA revisions. Sources:",
  "",
  paste0("- CE_REPORTING: <", ded_urls["CE_REPORTING"], ">"),
  paste0("- CE_CITATION: <", ded_urls["CE_CITATION"], ">"),
  "",
  paste("Retrieved:", Sys.Date()),
  "",
  imap(sections, \(cols, title) section_md(title, cols)) |> unlist()
)

writeLines(dictionary, dict_file)

cat("Dictionary columns:", nrow(elements), "\n")
cat("NDV pages written: ", length(ndv_slugs), "\n")
