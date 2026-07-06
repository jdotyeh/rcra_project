# Scrape the RCRAInfo download summary page from EPA ECHO:
#   - the "RCRAInfo Description" section is saved as RCRA_READ_ME.md
#   - everything else (guidance, file structure tables, code lookups, and the
#     data element dictionary) is saved as RCRA_DATA_DICTIONARY.md, with the
#     text-formatted element definitions converted to tables
# Source: https://echo.epa.gov/tools/data-downloads/rcrainfo-download-summary
# Run from the repo root.

library(rvest)

url <- "https://echo.epa.gov/tools/data-downloads/rcrainfo-download-summary"
out_dir <- "data/echo_rcra"

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

page <- read_html(url)

# Clean text: replace non-breaking spaces (UTF-8 bytes C2 A0) with regular
# spaces, and escape pipes so they don't break the markdown tables
clean_text <- function(x) {
  x <- gsub("\xc2\xa0", " ", x, useBytes = TRUE)
  x <- gsub("|", "\\|", x, fixed = TRUE)
  trimws(x)
}

as_markdown_table <- function(tbl) {
  tbl[] <- lapply(tbl, clean_text)
  header <- paste("|", paste(clean_text(names(tbl)), collapse = " | "), "|")
  divider <- paste("|", paste(rep("---", ncol(tbl)), collapse = " | "), "|")
  rows <- apply(tbl, 1, function(r) paste("|", paste(r, collapse = " | "), "|"))
  c(header, divider, rows)
}

# Walk the main page content in order: headings, paragraphs, bullet lists,
# and tables. Content before the first heading (intro, table of contents)
# and "Top of Page" links are skipped. Consecutive element definitions
# ("NAME - description" paragraphs) are collected and written as one table
# with the element names highlighted in bold.
nodes <- html_elements(page, "main h2, main h3, main h4, main p, main ul, main table")

lines <- c("# RCRAInfo Data Dictionary", "", paste("Source:", url))
read_me <- c("# RCRAInfo Description", "", paste("Source:", url))
section <- ""

entry_names <- character()
entry_defs <- character()

flush_entries <- function() {
  if (length(entry_names) == 0) return(invisible())
  lines <<- c(
    lines, "",
    "| Element | Definition |",
    "| --- | --- |",
    paste0("| **", entry_names, "** | ", entry_defs, " |")
  )
  entry_names <<- character()
  entry_defs <<- character()
}

for (node in nodes) {
  tag <- html_name(node)
  in_read_me <- section == "RCRAInfo Description"

  if (tag %in% c("h2", "h3", "h4")) {
    flush_entries()
    section <- clean_text(html_text(node))
    if (section == "RCRAInfo Description") next
    level <- if (tag == "h2") "##" else "###"
    lines <- c(lines, "", paste(level, section))

  } else if (section == "") {
    next

  } else if (tag == "table") {
    flush_entries()
    lines <- c(lines, "", as_markdown_table(html_table(node)))

  } else if (tag == "ul") {
    flush_entries()
    items <- paste("-", clean_text(html_text(html_elements(node, "li"))))
    if (in_read_me) read_me <- c(read_me, "", items)
    else lines <- c(lines, "", items)

  } else {
    text <- clean_text(html_text(node))
    if (text == "" || text == "Top of Page") next

    # Element definitions look like "<strong>NAME</strong> - description"
    strong <- html_element(node, "strong")
    if (!in_read_me && !inherits(strong, "xml_missing")) {
      name <- clean_text(html_text(strong))
      def <- trimws(sub("^-+\\s*", "", trimws(substring(text, nchar(name) + 1))))
      entry_names <- c(entry_names, name)
      entry_defs <- c(entry_defs, def)
    } else {
      flush_entries()
      if (in_read_me) read_me <- c(read_me, "", text)
      else lines <- c(lines, "", text)
    }
  }
}
flush_entries()

writeLines(lines, file.path(out_dir, "RCRA_DATA_DICTIONARY.md"))
cat("Saved data dictionary to", file.path(out_dir, "RCRA_DATA_DICTIONARY.md"), "\n")

writeLines(read_me, file.path(out_dir, "RCRA_READ_ME.md"))
cat("Saved READ ME to", file.path(out_dir, "RCRA_READ_ME.md"), "\n")
