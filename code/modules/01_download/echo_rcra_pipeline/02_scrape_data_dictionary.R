# Scrape the RCRA pipeline data dictionary from the EPA ECHO summary page
# and save it as a markdown file in data/echo_rcra_pipeline.
# Source: https://echo.epa.gov/tools/data-downloads/rcra-pipeline-download-summary
# Run from the repo root.

library(rvest)

url <- "https://echo.epa.gov/tools/data-downloads/rcra-pipeline-download-summary"
out_dir <- "data/echo_rcra_pipeline"

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

page <- read_html(url)

# The page has one table: Element, Data Type, Length, Notes
dictionary <- html_table(page)[[1]]

# Clean cells: replace non-breaking spaces (UTF-8 bytes C2 A0) with regular
# spaces, and escape pipes so they don't break the markdown table
clean_cell <- function(x) {
  x <- gsub("\xc2\xa0", " ", x, useBytes = TRUE)
  gsub("|", "\\|", x, fixed = TRUE)
}
dictionary[] <- lapply(dictionary, clean_cell)

# Build a markdown table
header <- paste("|", paste(names(dictionary), collapse = " | "), "|")
divider <- paste("|", paste(rep("---", ncol(dictionary)), collapse = " | "), "|")
rows <- apply(dictionary, 1, function(r) paste("|", paste(r, collapse = " | "), "|"))

out_file <- file.path(out_dir, "PIPELINE_DATA_DICTIONARY.md")
writeLines(
  c("# RCRA Pipeline Data Dictionary", "", paste("Source:", url), "", header, divider, rows),
  out_file
)

cat("Saved data dictionary with", nrow(dictionary), "elements to", out_file, "\n")
