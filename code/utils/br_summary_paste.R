# Put Biennial Report summary tables on the clipboard for pasting into the
# Google Doc ("2026 RCRA Project" > Biennial Report Module > BR Summary Tables).
#
# Reads "output/summary_tables/Biennial Report <year> Summary Tables.xlsx"
# (all three tabs: Categorical, Quantitative, Dummy), rebuilds each sheet as an
# HTML table that mirrors the workbook's house format (fills, merged blocks,
# gray variable descriptions, borders, alignment), and puts the result on the
# macOS clipboard as rich HTML. Pasting into Google Docs (Cmd+V) then produces
# real Docs tables with the same look.
#
# Usage (from the repo root):
#   Rscript code/utils/br_summary_to_gdoc.R 2021
#       one year, tables only -- click the blank line UNDER the year's
#       Heading-3 line in the Doc and press Cmd+V
#   Rscript code/utils/br_summary_to_gdoc.R --with-headers 2019 2017 2015
#       several years in one paste; a Heading-3 year line is inserted before
#       each year's tables -- click at the end of the Doc and press Cmd+V
#
# macOS only (uses osascript for the clipboard). Not part of the replication
# pipeline; code/master.R does not run scripts in code/utils/.
# Requires: openxlsx2.

suppressMessages(library(openxlsx2))

# ---- helpers ----------------------------------------------------------------
esc <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  gsub("\n", "<br/>", x, fixed = TRUE)
}
col_letter_to_num <- function(s) {
  ch <- strsplit(s, "")[[1]]
  Reduce(function(a, b) a * 26 + b, match(ch, LETTERS))
}
parse_range <- function(r) {
  m <- regmatches(r, regexec("([A-Z]+)([0-9]+):([A-Z]+)([0-9]+)", r))[[1]]
  list(c1 = col_letter_to_num(m[2]), r1 = as.integer(m[3]),
       c2 = col_letter_to_num(m[4]), r2 = as.integer(m[5]))
}

BASE <- "border:1px solid #000000;font-family:Calibri;font-size:12pt;vertical-align:middle;padding:2px 5px;"

# render a cell matrix (with merges) as one bordered HTML table
render_table <- function(v, rows, ncols, widths, fills, aligns, cellfun, merges) {
  cover <- matrix(FALSE, nrow = max(rows), ncol = ncols)
  span  <- list()
  for (p in merges) {
    if (p$r1 %in% rows) {
      span[[paste(p$r1, p$c1)]] <- c(p$r2 - p$r1 + 1L, p$c2 - p$c1 + 1L)
      for (rr in p$r1:p$r2) for (cc in p$c1:p$c2)
        if (!(rr == p$r1 && cc == p$c1)) cover[rr, cc] <- TRUE
    }
  }
  out <- c('<table style="border-collapse:collapse;table-layout:fixed;">',
           "<colgroup>", sprintf('<col style="width:%dpx;"/>', widths), "</colgroup>")
  for (r in rows) {
    out <- c(out, "<tr>")
    for (cc in seq_len(ncols)) {
      if (cover[r, cc]) next
      sp <- span[[paste(r, cc)]]
      spat <- if (!is.null(sp)) sprintf(' rowspan="%d" colspan="%d"', sp[1], sp[2]) else ""
      val <- v[r, cc]; if (is.na(val)) val <- ""
      st <- paste0(BASE, fills(r, cc), aligns(r, cc))
      out <- c(out, sprintf('<td%s style="%s">%s</td>', spat, st, cellfun(r, cc, val)))
    }
    out <- c(out, "</tr>")
  }
  c(out, "</table>")
}

# single-cell note block (missing-value notes / dropped variables) -> 1x1 table
render_note <- function(text, width) {
  sprintf('<table style="border-collapse:collapse;table-layout:fixed;"><colgroup><col style="width:%dpx;"/></colgroup><tr><td style="border:1px solid #000000;font-family:Calibri;font-size:11pt;vertical-align:top;padding:2px 5px;">%s</td></tr></table>',
          width, esc(text))
}

# one worksheet -> main table + trailing note tables
sheet_html <- function(wb, sheet) {
  v <- as.matrix(wb_to_df(wb, sheet = sheet, col_names = FALSE, convert = FALSE))
  idx <- match(sheet, wb$get_sheet_names())
  mg_raw <- wb$worksheets[[idx]]$mergeCells
  merges <- lapply(regmatches(mg_raw, regexpr("[A-Z]+[0-9]+:[A-Z]+[0-9]+", mg_raw)), parse_range)

  if (sheet == "Categorical") {
    ncols <- 6; widths <- c(180, 117, 100, 154, 52, 70); datacols <- 2:6
  } else {
    ncols <- 7; datacols <- 2:7
    widths <- if (sheet == "Quantitative") c(145, 80, 62, 100, 100, 100, 100)
              else c(180, rep(80, 6))
  }
  nonempty  <- function(r) any(!is.na(v[r, datacols]))
  main_last <- max(which(vapply(seq_len(nrow(v)), nonempty, TRUE)))

  hdr_fill <- c(Categorical = "#D2F3C6", Quantitative = "#A6C9EC", Dummy = "#FFD966")[[sheet]]
  fills <- function(r, cc) {
    if (sheet == "Categorical" && r <= 5) return("background-color:#B5E6A2;")
    if (sheet == "Categorical" && r == 6) return(paste0("background-color:", hdr_fill, ";"))
    if (sheet != "Categorical" && r == 1) return(paste0("background-color:", hdr_fill, ";"))
    ""
  }
  is_num <- function(x) !is.na(suppressWarnings(as.numeric(x)))
  aligns <- function(r, cc) {
    if (sheet == "Categorical") {
      if (r >= 7 && cc %in% 2:3) return("text-align:center;")
      if (r >= 7 && cc %in% 5:6) return("text-align:right;")
      if (r %in% 3:4 && cc == 2) return("text-align:right;")
      return("")
    }
    if (r > 1 && cc >= 2) {
      val <- v[r, cc]
      if (!is.na(val) && (is_num(val) || grepl("^\\d{4}-\\d{2}-\\d{2}$", val)))
        return("text-align:right;white-space:nowrap;")
    }
    ""
  }
  cellfun <- function(r, cc, val) {
    if (val == "") return("")
    # % column shows one decimal, as in the workbook (numfmt 0.0)
    if (sheet == "Categorical" && cc == 5 && r >= 7 && is_num(val))
      return(sprintf("%.1f", as.numeric(val)))
    # variable cells: name in black, description in gray under it
    if (sheet == "Categorical" && cc == 1 && r >= 7 && grepl("\n", val)) {
      parts <- strsplit(val, "\n")[[1]]
      return(paste0(esc(parts[1]), "<br/>",
                    '<span style="color:#666666;">',
                    paste(vapply(parts[-1], esc, ""), collapse = "<br/>"), "</span>"))
    }
    esc(val)
  }

  html <- render_table(v, seq_len(main_last), ncols, widths, fills, aligns, cellfun, merges)
  for (p in merges) {                      # note blocks sit below the main table
    if (p$r1 > main_last)
      html <- c(html, "<p></p>", render_note(v[p$r1, 1], sum(widths)))
  }
  paste(html, collapse = "\n")
}

# all three sheets of one year's workbook
year_html <- function(year) {
  wb <- wb_load(sprintf("output/summary_tables/Biennial Report %d Summary Tables.xlsx", year))
  paste(vapply(wb$get_sheet_names(), function(s) sheet_html(wb, s), ""),
        collapse = "\n<p></p>\n")
}

# Heading-3 year line, matching the Doc's header style (Georgia 14 bold)
year_header <- function(year)
  sprintf('<h3 style="font-family:Georgia;font-size:14pt;font-weight:bold;color:#000000;">%d</h3>', year)

# put HTML on the macOS clipboard as the rich-text (HTML) flavor. The
# AppleScript goes through a temp file (not -e) because the guillemets in
# "as <<class HTML>>" (written \u00ab / \u00bb to stay locale-proof) don't
# survive argv translation in system2().
copy_html_to_clipboard <- function(html) {
  write_utf8 <- function(lines, path) {
    con <- file(path, open = "wb")
    on.exit(close(con))
    writeLines(enc2utf8(lines), con, useBytes = TRUE)
  }
  tmp <- tempfile(fileext = ".html")
  write_utf8(html, tmp)
  scpt <- tempfile(fileext = ".applescript")
  write_utf8(sprintf('set the clipboard to (read (POSIX file "%s") as \u00abclass HTML\u00bb)', tmp), scpt)
  status <- system2("osascript", scpt)
  if (status != 0) stop("osascript failed; clipboard not set")
}

# ---- CLI ---------------------------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)
with_headers <- "--with-headers" %in% args
years <- suppressWarnings(as.integer(setdiff(args, "--with-headers")))
if (!length(years) || anyNA(years)) {
  stop(paste("Usage: Rscript code/utils/br_summary_to_gdoc.R [--with-headers] <year> [<year> ...]",
             "Years must match workbooks in output/summary_tables/.", sep = "\n"))
}

chunks <- lapply(years, function(y) {
  if (with_headers) paste(year_header(y), year_html(y), sep = "\n") else year_html(y)
})
copy_html_to_clipboard(paste(unlist(chunks), collapse = "\n<p></p>\n"))

cat(sprintf("Clipboard ready: %s%s.\n",
            paste(years, collapse = ", "),
            if (with_headers) " (with Heading-3 year lines)" else ""))
cat(if (with_headers)
  "In the Google Doc, click at the end of the tab and press Cmd+V.\n" else
  "In the Google Doc, click the blank line under the year's header and press Cmd+V.\n")
