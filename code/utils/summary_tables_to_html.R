# =============================================================================
# FILE:     summary_tables_to_html.R
# PURPOSE:  Compile the summary-table workbooks into two standalone HTML files
#           that mirror the workbook house format. A convenience tool, not part
#           of the pipeline; master.R never runs it.
# INPUTS:   output/summary_tables/*.xlsx (the module and Biennial Report books)
# OUTPUTS:  output/summary_tables/Modular Summary Tables.html,
#           output/summary_tables/Biennial Report Summary Tables.html
# AUTHOR:   Jason Ye
# CREATED:  2026-07-14
# UPDATED:  2026-07-14
# =============================================================================

# Compile the RCRAInfo summary-table workbooks into two standalone HTML files:
#
#   output/summary_tables/Modular Summary Tables.html
#       the seven module workbooks (Handler, CME, Corrective Action, Permitting,
#       Financial Assurance, WIETS exports/imports)
#   output/summary_tables/Biennial Report Summary Tables.html
#       the twelve Biennial Report cycles (2001-2023)
#
# Each workbook's sheets (Categorical, Quantitative, Dummy) are rebuilt as HTML
# tables that mirror the .xlsx house format (fills, merged variable blocks, gray
# descriptions, borders, alignment, note blocks). Every file opens with a table
# of contents whose links jump straight to a workbook or to one of its tables,
# and every heading carries a "Back to top" button.
#
# Usage (from the repo root):
#   Rscript code/utils/summary_tables_to_html.R            # both files
#   Rscript code/utils/summary_tables_to_html.R modular    # modular only
#   Rscript code/utils/summary_tables_to_html.R br         # Biennial Report only
#
# Not part of the replication pipeline (code/master.R does not run code/utils/);
# the workbooks must already exist in output/summary_tables/ (built by
# code/modules/04_summary_tables/). Requires: openxlsx2.

suppressMessages(library(openxlsx2))

OUT_DIR <- "output/summary_tables"

# ---- house-format -> HTML helpers (mirror the .xlsx look) -------------------
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

BASE <- "border:1px solid #000000;color:#000000;font-size:12pt;vertical-align:middle;padding:2px 5px;"

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
  sprintf('<table style="border-collapse:collapse;table-layout:fixed;"><colgroup><col style="width:%dpx;"/></colgroup><tr><td style="border:1px solid #000000;font-size:11pt;vertical-align:top;padding:2px 5px;">%s</td></tr></table>',
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
  } else if (sheet == "Quantitative") {
    ncols <- 7; datacols <- 2:7; widths <- c(145, 80, 62, 100, 100, 100, 100)
  } else {
    # Dummy: nine columns since the Unknown pair was added for the "U" code.
    ncols <- 9; datacols <- 2:9; widths <- c(180, rep(80, 8))
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

# ---- page assembly ----------------------------------------------------------
# anchor-safe slug: "WIETS Exports Module" -> "wiets-exports-module"
slug <- function(s) {
  s <- tolower(s)
  s <- gsub("[^a-z0-9]+", "-", s)
  gsub("^-+|-+$", "", s)
}

BACKLINK <- ' <a class="toplink" href="#top">Back to top</a>'

# one workbook -> its TOC entry, its body section, and its tab count
workbook_section <- function(path, label) {
  wb     <- wb_load(path)
  sheets <- wb$get_sheet_names()
  sid    <- slug(label)

  subs <- vapply(sheets, function(s)
    sprintf('<li><a href="#%s-%s">%s</a></li>', sid, slug(s), esc(s)), "")
  nav <- sprintf('<li><a href="#%s">%s</a>\n      <ul class="toc-sub">%s</ul></li>',
                 sid, esc(label), paste(subs, collapse = ""))

  blocks <- vapply(sheets, function(s)
    sprintf('<h3 id="%s-%s" class="tab-title">%s%s</h3>\n<div class="tablewrap">%s</div>',
            sid, slug(s), esc(s), BACKLINK, sheet_html(wb, s)), "")
  body <- sprintf('<section id="%s" class="mod">\n<h2 class="mod-title">%s%s</h2>\n%s\n</section>',
                  sid, esc(label), BACKLINK, paste(blocks, collapse = "\n"))

  list(nav = nav, body = body, ntab = length(sheets))
}

PAGE_CSS <- '
:root{
  --ink:#1a1a1a; --muted:#5b6470; --faint:#7b838d;
  --navy:#232D4B; --orange:#E57200; --line:#d3d8d8; --gray-2:#eef1f1; --card:#ffffff;
  --sans:"Libre Franklin",-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
  --serif:"Lora",Georgia,"Times New Roman",serif;
}
* { box-sizing:border-box; }
body { margin:0; padding:0 28px 120px; color:var(--ink); background:var(--card);
       font-family:var(--sans); font-size:15px; line-height:1.5;
       -webkit-font-smoothing:antialiased; text-rendering:optimizeLegibility; }
header.page { padding:28px 0 16px; border-bottom:3px solid var(--orange); margin-bottom:6px; }
.eyebrow { margin:0 0 8px; font-family:var(--sans); font-size:11.5px; letter-spacing:.11em;
           text-transform:uppercase; color:var(--navy); font-weight:600; }
header.page h1 { margin:0 0 6px; font-family:var(--serif); font-weight:600;
                 font-size:clamp(24px,3.4vw,32px); letter-spacing:-.01em; color:var(--ink); }
.sub { color:var(--muted); margin:3px 0; font-size:14px; }
.legend { margin-top:14px; font-size:13px; color:var(--muted); }
.swatch { display:inline-block; width:12px; height:12px; border:1px solid #000;
          vertical-align:-1px; margin:0 5px 0 14px; }
.legend .swatch:first-child { margin-left:6px; }
nav.toc { margin:22px 0 6px; padding:16px 22px; background:var(--card);
          border:1px solid var(--line); border-radius:6px; }
nav.toc h2 { margin:0 0 10px; font-family:var(--serif); font-weight:600; font-size:18px; }
.toc-list { margin:0; padding-left:22px; }
.toc-list > li { margin:5px 0; font-weight:600; }
.toc-sub { margin:2px 0 8px; padding-left:18px; font-weight:400; }
.toc-sub li { margin:1px 0; font-size:14px; }
nav.toc a { color:var(--navy); text-decoration:none; }
nav.toc a:hover { color:var(--orange); text-decoration:underline; }
section.mod { padding-top:8px; margin-top:26px; border-top:1px solid var(--line); }
.mod-title { font-family:var(--serif); font-weight:600; font-size:22px; margin:16px 0 4px; }
.tab-title { font-family:var(--serif); font-weight:600; font-size:19px; margin:20px 0 8px; color:var(--navy); }
.toplink { display:inline-block; font-family:var(--sans); font-size:11px; font-weight:600;
           letter-spacing:.06em; text-transform:uppercase; margin-left:12px; padding:4px 11px;
           background:#e9eef6; color:var(--navy); border-radius:4px; text-decoration:none;
           vertical-align:middle; }
.toplink:hover { background:#dbe4f2; color:var(--navy); }
.tablewrap { overflow-x:auto; padding:2px 0 6px; }'

LEGEND <-
  '<p class="legend">Each table is colour-coded as in the source workbook:
   <span class="swatch" style="background:#D2F3C6;"></span>Categorical
   <span class="swatch" style="background:#A6C9EC;"></span>Quantitative
   <span class="swatch" style="background:#FFD966;"></span>Dummy</p>'

write_utf8 <- function(lines, path) {
  con <- file(path, open = "wb"); on.exit(close(con))
  writeLines(enc2utf8(lines), con, useBytes = TRUE)
}

# build one HTML file from an ordered list of list(path=, label=) items
build_page <- function(title, subtitle, items, out_file) {
  items <- Filter(function(it) {
    if (file.exists(it$path)) return(TRUE)
    warning(sprintf("skipping missing workbook: %s", it$path), call. = FALSE); FALSE
  }, items)
  if (!length(items)) stop("no workbooks found under ", OUT_DIR)

  secs   <- lapply(items, function(it) workbook_section(it$path, it$label))
  n_wb   <- length(secs)
  n_tab  <- sum(vapply(secs, function(s) s$ntab, 0L))
  stamp  <- format(Sys.time(), "%Y-%m-%d %H:%M")

  html <- c(
    '<!DOCTYPE html>',
    '<html lang="en">',
    '<head>',
    '<meta charset="utf-8"/>',
    '<meta name="viewport" content="width=device-width, initial-scale=1"/>',
    sprintf('<title>%s</title>', esc(title)),
    '<link rel="preconnect" href="https://fonts.googleapis.com"/>',
    '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>',
    paste0('<link rel="stylesheet" href="https://fonts.googleapis.com/css2?',
           'family=Libre+Franklin:wght@300;400;500;600;700&family=Lora:wght@400;500;600;700&display=swap"/>'),
    sprintf('<style>%s</style>', PAGE_CSS),
    '</head>',
    '<body>',
    '<header class="page" id="top">',
    '<p class="eyebrow">RCRA Regulatory Data Infrastructure</p>',
    sprintf('<h1>%s</h1>', esc(title)),
    sprintf('<p class="sub">%s</p>', esc(subtitle)),
    sprintf('<p class="sub">%d workbooks &middot; %d tables &middot; generated %s</p>',
            n_wb, n_tab, stamp),
    LEGEND,
    '</header>',
    '<nav class="toc">',
    '<h2>Contents</h2>',
    '<ol class="toc-list">',
    paste(vapply(secs, function(s) s$nav, ""), collapse = "\n"),
    '</ol>',
    '</nav>',
    paste(vapply(secs, function(s) s$body, ""), collapse = "\n"),
    '</body>',
    '</html>')

  dir.create(dirname(out_file), recursive = TRUE, showWarnings = FALSE)
  write_utf8(html, out_file)
  cat(sprintf("Wrote %s  (%d workbooks, %d tables)\n", out_file, n_wb, n_tab))
  invisible(out_file)
}

# ---- what goes in each file -------------------------------------------------
item <- function(label) list(path = file.path(OUT_DIR, paste0(label, " Summary Tables.xlsx")),
                             label = label)

modular_items <- lapply(c(
  "Handler Module", "CME Module", "Corrective Action Module", "Permitting Module",
  "Financial Assurance Module", "WIETS Exports Module", "WIETS Imports Module"), item)

br_items <- lapply(sprintf("Biennial Report %d", seq(2001, 2023, by = 2)), item)

build_modular <- function()
  build_page("RCRAInfo Modular Summary Tables",
             "Every coded, dated, numeric, and indicator field of each RCRAInfo module master file.",
             modular_items, file.path(OUT_DIR, "Modular Summary Tables.html"))

build_br <- function()
  build_page("RCRAInfo Biennial Report Summary Tables",
             "Variable-level summaries of each Biennial Report cycle, 2001-2023.",
             br_items, file.path(OUT_DIR, "Biennial Report Summary Tables.html"))

# ---- CLI --------------------------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)
which <- if (!length(args)) c("modular", "br") else tolower(args)
bad   <- setdiff(which, c("modular", "br"))
if (length(bad))
  stop("Usage: Rscript code/utils/summary_tables_to_html.R [modular] [br]\n",
       "  unknown argument(s): ", paste(bad, collapse = ", "))
if ("modular" %in% which) build_modular()
if ("br"      %in% which) build_br()
