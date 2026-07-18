# =============================================================================
# FILE:     02_scrape_data_dictionary.R
# PURPOSE:  Scrape the ECHO RCRAInfo download-summary page into a markdown data
#           dictionary and a markdown copy of the bundled read me.
# INPUTS:   https://echo.epa.gov/tools/data-downloads/rcrainfo-download-summary
# OUTPUTS:  data/echo_rcra/RCRA_DATA_DICTIONARY.md, data/echo_rcra/RCRA_READ_ME.md
# AUTHOR:   Jason Ye
# CREATED:  2026-07-06
# UPDATED:  2026-07-06
# =============================================================================

# Scrape the RCRAInfo download summary page from EPA ECHO:
#   - the "RCRAInfo Description" section is saved as RCRA_READ_ME.md
#   - everything else (guidance, file structure tables, code lookups, and the
#     data element dictionary) is saved as RCRA_DATA_DICTIONARY.md, with the
#     text-formatted element definitions converted to tables
# Source: https://echo.epa.gov/tools/data-downloads/rcrainfo-download-summary
# Run from the repo root.

# Load rvest for HTML scraping.
library(rvest)

# Set the page to scrape and the folder the markdown files land in.
url <- "https://echo.epa.gov/tools/data-downloads/rcrainfo-download-summary"
out_dir <- "data/echo_rcra"

# Create the output folder if it does not already exist.
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Fetch and parse the page HTML.
page <- read_html(url)

# Clean scraped text before it goes into markdown.
clean_text <- function(x) {
  x <- gsub("\xc2\xa0", " ", x, useBytes = TRUE)  # replace non-breaking spaces (UTF-8 bytes C2 A0)
  x <- gsub("|", "\\|", x, fixed = TRUE)          # escape pipes so they don't break markdown tables
  trimws(x)                                       # trim surrounding whitespace
}

# Convert a scraped data frame into markdown table lines.
as_markdown_table <- function(tbl) {
  # Clean every cell.
  tbl[] <- lapply(tbl, clean_text)
  # Build the header row, the divider row, and one line per data row.
  header <- paste("|", paste(clean_text(names(tbl)), collapse = " | "), "|")
  divider <- paste("|", paste(rep("---", ncol(tbl)), collapse = " | "), "|")
  rows <- apply(tbl, 1, function(r) paste("|", paste(r, collapse = " | "), "|"))
  # Return the assembled table lines.
  c(header, divider, rows)
}

# Walk the main page content in order: headings, paragraphs, bullet lists,
# and tables. Content before the first heading (intro, table of contents)
# and "Top of Page" links are skipped. Consecutive element definitions
# ("NAME - description" paragraphs) are collected and written as one table
# with the element names highlighted in bold.
nodes <- html_elements(page, "main h2, main h3, main h4, main p, main ul, main table")

# Start each output document with a title and the source link.
lines <- c("# RCRAInfo Data Dictionary", "", paste("Source:", url))
read_me <- c("# RCRAInfo Description", "", paste("Source:", url))
# Track the current section heading; "" means no heading seen yet.
section <- ""

# Collect consecutive element definitions here until a non-definition node ends the run.
entry_names <- character()
entry_defs <- character()

# Write the collected element definitions as one markdown table, then reset.
flush_entries <- function() {
  # Skip when no definitions are waiting.
  if (length(entry_names) == 0) return(invisible())
  # Append the definitions as a two-column table with the names in bold.
  lines <<- c(
    lines, "",
    "| Element | Definition |",
    "| --- | --- |",
    paste0("| **", entry_names, "** | ", entry_defs, " |")
  )
  # Reset the collectors.
  entry_names <<- character()
  entry_defs <<- character()
}

for (node in nodes) {
  # Read the tag name and check whether we are inside the read-me section.
  tag <- html_name(node)
  in_read_me <- section == "RCRAInfo Description"

  if (tag %in% c("h2", "h3", "h4")) {
    # Close any open definition run and start a new section.
    flush_entries()
    section <- clean_text(html_text(node))
    # Skip writing the read-me heading; its content goes to the other file.
    if (section == "RCRAInfo Description") next
    # Map h2 to ## and deeper headings to ###.
    level <- if (tag == "h2") "##" else "###"
    lines <- c(lines, "", paste(level, section))

  } else if (section == "") {
    # Skip content before the first heading (intro, table of contents).
    next

  } else if (tag == "table") {
    # Write the table as markdown.
    flush_entries()
    lines <- c(lines, "", as_markdown_table(html_table(node)))

  } else if (tag == "ul") {
    # Write the bullet list, one markdown item per list entry.
    flush_entries()
    items <- paste("-", clean_text(html_text(html_elements(node, "li"))))
    if (in_read_me) read_me <- c(read_me, "", items)
    else lines <- c(lines, "", items)

  } else {
    # Clean the paragraph text and skip empty or "Top of Page" lines.
    text <- clean_text(html_text(node))
    if (text == "" || text == "Top of Page") next

    # Detect element definitions, which look like "<strong>NAME</strong> - description".
    strong <- html_element(node, "strong")
    if (!in_read_me && !inherits(strong, "xml_missing")) {
      # Split the paragraph into the element name and its definition, then collect it.
      name <- clean_text(html_text(strong))
      def <- trimws(sub("^-+\\s*", "", trimws(substring(text, nchar(name) + 1))))
      entry_names <- c(entry_names, name)
      entry_defs <- c(entry_defs, def)
    } else {
      # Write a plain paragraph to whichever document the section belongs to.
      flush_entries()
      if (in_read_me) read_me <- c(read_me, "", text)
      else lines <- c(lines, "", text)
    }
  }
}
# Write any definitions still waiting at the end of the page.
flush_entries()

# Save the data dictionary and report where it went.
writeLines(lines, file.path(out_dir, "RCRA_DATA_DICTIONARY.md"))
cat("Saved data dictionary to", file.path(out_dir, "RCRA_DATA_DICTIONARY.md"), "\n")

# Save the read me and report where it went.
writeLines(read_me, file.path(out_dir, "RCRA_READ_ME.md"))
cat("Saved READ ME to", file.path(out_dir, "RCRA_READ_ME.md"), "\n")
