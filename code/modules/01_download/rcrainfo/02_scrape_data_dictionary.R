# Scrape the RCRAInfo Public Data Element Dictionary (DED) help pages and
# save one markdown dictionary per module folder, next to the module's data:
# data/rcrainfo/ce/CE_DATA_DICTIONARY.md, data/rcrainfo/br/..., etc.
# Source: https://rcrainfo.epa.gov/rcrainfo-help/application/publicHelp/index.htm
# Run from the repo root.

library(rvest)
library(xml2)

base_url <- "https://rcrainfo.epa.gov/rcrainfo-help/application/publicHelp/DataElementDictionary/"
out_root <- "data/rcrainfo"

# DED pages for each module (module pages plus reporting table pages)
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

# Clean text: replace non-breaking spaces (UTF-8 bytes C2 A0) with regular
# spaces, and escape pipes so they don't break the markdown tables
clean_text <- function(x) {
  x <- gsub("\xc2\xa0", " ", x, useBytes = TRUE)
  x <- gsub("|", "\\|", x, fixed = TRUE)
  trimws(gsub("\\s+", " ", x))
}

as_markdown_table <- function(tbl) {
  # These tables carry their header in the first row (rvest names them X1, X2, ...)
  if (all(grepl("^X\\d+$", names(tbl)))) {
    header_row <- as.character(unlist(tbl[1, ]))
    header_row[is.na(header_row) | header_row == ""] <- " "
    names(tbl) <- header_row
    tbl <- tbl[-1, , drop = FALSE]
  }
  tbl[] <- lapply(tbl, clean_text)
  header <- paste("|", paste(clean_text(names(tbl)), collapse = " | "), "|")
  divider <- paste("|", paste(rep("---", ncol(tbl)), collapse = " | "), "|")
  rows <- apply(tbl, 1, function(r) paste("|", paste(r, collapse = " | "), "|"))
  c(header, divider, rows)
}

for (module in names(pages)) {
  lines <- c(
    paste0("# ", toupper(module), " Data Dictionary (RCRAInfo)"), "",
    paste0("Source: ", base_url, "(", paste(pages[[module]], collapse = ", "), ")")
  )

  for (page_name in pages[[module]]) {
    page <- read_html(paste0(base_url, page_name))
    nodes <- html_elements(page, "h1, h2, h3, h4, table, p")

    for (node in nodes) {
      tag <- html_name(node)

      # Skip paragraphs that sit inside tables (already covered by the table)
      # and wrapper tables that contain other tables (page layout only)
      if (tag == "p" && length(xml_find_all(node, "ancestor::table")) > 0) next
      if (tag == "table" && length(html_elements(node, "table")) > 0) next

      if (tag == "table") {
        # Some tables have empty header cells, which makes html_table warn
        tbl <- suppressWarnings(html_table(node))
        # One-column tables are page decoration (table name banners), not data
        if (ncol(tbl) > 1) lines <- c(lines, "", as_markdown_table(tbl))
        next
      }

      text <- clean_text(html_text(node))
      if (text == "" || text == "Click here to see this page in full context") next

      if (tag == "h1") {
        lines <- c(lines, "", paste("##", text))
      } else if (tag %in% c("h2", "h3", "h4")) {
        lines <- c(lines, "", paste("###", text))
      } else {
        lines <- c(lines, "", text)
      }
    }
  }

  out_file <- file.path(out_root, module, paste0(toupper(module), "_DATA_DICTIONARY.md"))
  writeLines(lines, out_file)
  cat("Saved", out_file, "\n")
}
