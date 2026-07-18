# =============================================================================
# FILE:     02_scrape_data_dictionary.R
# PURPOSE:  Scrape the RCRAInfo Public Data Element Dictionary help pages into a
#           markdown data dictionary for each module, saved beside the data.
# INPUTS:   RCRAInfo DED help site
#           (https://rcrainfo.epa.gov/rcrainfo-help/application/publicHelp/)
# OUTPUTS:  data/rcrainfo/<module>/<MODULE>_DATA_DICTIONARY.md
# AUTHOR:   Jason Ye
# CREATED:  2026-07-06
# UPDATED:  2026-07-06
# =============================================================================

# Scrape the RCRAInfo Public Data Element Dictionary (DED) help pages and
# save one markdown dictionary per module folder, next to the module's data:
# data/rcrainfo/ce/CE_DATA_DICTIONARY.md, data/rcrainfo/br/..., etc.
# Source: https://rcrainfo.epa.gov/rcrainfo-help/application/publicHelp/index.htm
# Run from the repo root.

# Load rvest and xml2 for HTML scraping.
library(rvest)
library(xml2)

# Set the DED help-site base and the output root.
base_url <- "https://rcrainfo.epa.gov/rcrainfo-help/application/publicHelp/DataElementDictionary/"
out_root <- "data/rcrainfo"

# Map each module to its DED pages (module pages plus reporting table pages).
pages <- list(
  br = c("DED-BiennialReportModule.htm", "DED-BRReportingTables.htm"),
  ca = "DED-CorrectiveActionModule.htm",
  ce = c("DED-CMEModule.htm", "DED-CMEReportingTables.htm"),
  em = "DED-EManifestModule.htm",
  fa = "DED-FinancialAssuranceModule.htm",
  hd = c("DED-HandlerModule.htm", "DED-HandlerReportingTables.htm"),
  pm = "DED-PermittingModule.htm",
  wt = "DED-WIETSPublicReportingTables.htm"
)

# Clean scraped text before it goes into markdown.
clean_text <- function(x) {
  x <- gsub("\xc2\xa0", " ", x, useBytes = TRUE)  # replace non-breaking spaces (UTF-8 bytes C2 A0)
  x <- gsub("|", "\\|", x, fixed = TRUE)          # escape pipes so they don't break markdown tables
  trimws(gsub("\\s+", " ", x))                    # collapse runs of whitespace and trim
}

# Convert a scraped data frame into markdown table lines.
as_markdown_table <- function(tbl) {
  # Promote the first row to header when rvest supplied placeholder names (X1, X2, ...).
  if (all(grepl("^X\\d+$", names(tbl)))) {
    header_row <- as.character(unlist(tbl[1, ]))
    header_row[is.na(header_row) | header_row == ""] <- " "
    names(tbl) <- header_row
    tbl <- tbl[-1, , drop = FALSE]
  }
  # Clean every cell.
  tbl[] <- lapply(tbl, clean_text)
  # Build the header row, the divider row, and one line per data row.
  header <- paste("|", paste(clean_text(names(tbl)), collapse = " | "), "|")
  divider <- paste("|", paste(rep("---", ncol(tbl)), collapse = " | "), "|")
  rows <- apply(tbl, 1, function(r) paste("|", paste(r, collapse = " | "), "|"))
  # Return the assembled table lines.
  c(header, divider, rows)
}

# Build one markdown dictionary per module.
for (module in names(pages)) {
  # Start the document with a title and the source pages.
  lines <- c(
    paste0("# ", toupper(module), " Data Dictionary (RCRAInfo)"), "",
    paste0("Source: ", base_url, "(", paste(pages[[module]], collapse = ", "), ")")
  )

  for (page_name in pages[[module]]) {
    # Fetch the page and select its content nodes in document order.
    page <- read_html(paste0(base_url, page_name))
    nodes <- html_elements(page, "h1, h2, h3, h4, table, p")

    for (node in nodes) {
      tag <- html_name(node)

      # Skip paragraphs that sit inside tables (already covered by the table)
      # and wrapper tables that contain other tables (page layout only).
      if (tag == "p" && length(xml_find_all(node, "ancestor::table")) > 0) next
      if (tag == "table" && length(html_elements(node, "table")) > 0) next

      if (tag == "table") {
        # Parse the table, suppressing the warning empty header cells cause.
        tbl <- suppressWarnings(html_table(node))
        # Keep only real data tables; one-column tables are page decoration.
        if (ncol(tbl) > 1) lines <- c(lines, "", as_markdown_table(tbl))
        next
      }

      # Clean the node text and skip empty or boilerplate lines.
      text <- clean_text(html_text(node))
      if (text == "" || text == "Click here to see this page in full context") next

      # Write h1 as ##, deeper headings as ###, and paragraphs as plain text.
      if (tag == "h1") {
        lines <- c(lines, "", paste("##", text))
      } else if (tag %in% c("h2", "h3", "h4")) {
        lines <- c(lines, "", paste("###", text))
      } else {
        lines <- c(lines, "", text)
      }
    }
  }

  # Save the module's dictionary next to its data.
  out_file <- file.path(out_root, module, paste0(toupper(module), "_DATA_DICTIONARY.md"))
  writeLines(lines, out_file)
  cat("Saved", out_file, "\n")
}
