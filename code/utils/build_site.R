# =============================================================================
# FILE:     build_site.R
# PURPOSE:  Assemble the public project website under docs/ from artifacts the
#           repository already holds. A convenience tool, not part of the
#           pipeline; master.R never runs it.
# INPUTS:   output/summary_tables/Modular Summary Tables.html and Biennial Report
#           Summary Tables.html; docs/institutional_briefs/*.md; resources/table.md;
#           resources/batten-logo.png
# OUTPUTS:  docs/index.html, docs/briefs.html, docs/briefs/*.html,
#           docs/summary_tables/*.html, docs/assets/site.css
#           (docs/state-reporting.html only on an explicit forced run)
# AUTHOR:   Jason Ye
# CREATED:  2026-07-16
# UPDATED:  2026-07-22
# =============================================================================

# Build the public project website into docs/ (published by GitHub Pages).
#
#   docs/index.html            front door: overview, pipeline, data, outputs
#   docs/briefs.html           contents page for the institutional briefs
#   docs/briefs/               one page per brief, rendered from the markdown in
#                              docs/institutional_briefs/ (which stays the source)
#   docs/state-reporting.html  searchable state-by-state RCRA reporting reference
#                              (hand-revised; see the note above build_state)
#   docs/summary_tables/       the two compiled summary-table pages, copied in
#     modular.html               from output/summary_tables/Modular Summary Tables.html
#     biennial-report.html       from output/summary_tables/Biennial Report Summary Tables.html
#   docs/assets/site.css       one shared stylesheet (serif display + sans body)
#   docs/assets/batten-logo.png  official UVA Batten lockup (copied from resources/)
#
# The site is a thin, additive layer over artifacts the pipeline already builds.
# It is NOT part of the replication pipeline: code/master.R does not run
# code/utils/, and this script adds no dependency beyond base R. Re-run it after
# the summary tables (code/modules/04_summary_tables/) and their HTML compilation
# (code/utils/summary_tables_to_html.R) have been built, to refresh the site.
#
# Usage (from the repo root):
#   Rscript code/utils/build_site.R           # css, assets, index, briefs, summaries
#   Rscript code/utils/build_site.R briefs    # only the briefs and their contents page
#   Rscript code/utils/build_site.R index     # only the front page
#
# SITE_CSS below is the single source for docs/assets/site.css, and a build
# overwrites that file. Any styling change belongs in SITE_CSS, never in the
# generated stylesheet, or the next build will discard it.
#
# GitHub Pages: enable Pages on the default branch with the /docs folder as the
# source; the site then serves at https://<user>.github.io/rcra_project/. The
# body text renders in a webfont when online and falls back to system fonts
# otherwise, so the pages also open by double-clicking docs/index.html.

REPO        <- "https://github.com/jdotyeh/rcra_project"
DOCS        <- "docs"
ASSETS      <- file.path(DOCS, "assets")
SUMMARY_DIR <- "output/summary_tables"
TABLE_MD    <- "resources/table.md"

# ---- headline facts (curated copy; the README stays the canonical record) ----
STATS <- list(
  c("4",     "EPA data sources"),
  c("7",     "RCRAInfo modules"),
  c("12",    "Biennial cycles"),
  c("5",     "Facility panels"),
  c("~45",   "GB, reproducible"))

STAGES <- list(
  c("01", "Download",
    "Three EPA RCRA data sources pulled at run time from ECHO and RCRAInfo / HWIP, each with its data dictionary scraped alongside, plus the FRS Program Links crosswalk."),
  c("02", "Master files",
    "One analysis-ready CSV per module, each central table joined to its dimension tables with identifiers preserved verbatim and indicators recoded to 1/0."),
  c("03", "Panels",
    "Five facility panels built from the master files and the Biennial Report, two facility-cycle and three facility-month, each linked to EPA Facility Registry Service IDs and carrying FRS coordinates."),
  c("04", "Summary tables",
    "Every coded, dated, numeric, and indicator field of every module master file summarized variable by variable: categorical frequencies, quantitative ranges, and 1/0 indicators."))

# grouped data sources: label, tag, one-line description, landing-page URL.
# The name renders as a link to the EPA page the download stage pulls from, so
# keep the fourth element populated for every item.
SOURCES <- list(
  list(group = "Core RCRA", items = list(
    c("ECHO RCRA Pipeline",  "EPA / ECHO",   "Compliance-monitoring activities with linked violations and enforcement actions.",
      "https://echo.epa.gov/tools/data-downloads/rcra-pipeline-download-summary"),
    c("ECHO RCRAInfo",       "EPA / ECHO",   "Compliance and enforcement extract for hazardous-waste sites.",
      "https://echo.epa.gov/tools/data-downloads/rcrainfo-download-summary"),
    c("RCRAInfo CSV exports","EPA / HWIP",   "Complete module tables: Biennial Report, Corrective Action, CME, e-Manifest, Financial Assurance, Handler, Permitting, WIETS.",
      "https://rcrapublic.epa.gov/rcra-hwip/data-access/csv-downloads"))),
  list(group = "Diagnostics inventories (outside the pipeline)", items = list(
    c("TRI",   "EPA", "Toxics Release Inventory Basic Plus files, 2011-2024.",
      "https://www.epa.gov/toxics-release-inventory-tri-program/tri-basic-plus-data-files-calendar-years-1987-present"),
    c("NEI",   "EPA", "National Emissions Inventory point-source extracts, 2011-2022.",
      "https://www.epa.gov/air-emissions-inventories/national-emissions-inventory-nei"),
    c("GHGRP", "EPA", "Greenhouse Gas Reporting Program data and Envirofacts tables, 2011-2023.",
      "https://www.epa.gov/ghgreporting/data-sets"),
    c("eGRID", "EPA", "Plant-level generation and emissions workbooks.",
      "https://www.epa.gov/egrid"),
    c("DMR",   "EPA", "Discharge Monitoring Report annual pollutant loadings, 2014-2023.",
      "https://echo.epa.gov/trends/loading-tool/get-data"))),
  list(group = "Crosswalk", items = list(
    c("FRS Program Links", "EPA / FRS", "Facility Registry Service crosswalk that attaches a shared facility ID.",
      "https://www.epa.gov/frs/frs-data-resources"))))

# output cards: title, description, href (or "" when nothing is published), meta
CARDS <- list(
  list(title = "Institutional briefs",
       desc  = "What the hazardous-waste program is and how each rule shapes the records, one brief per topic, each ending in what it implies for the data.",
       href  = "briefs.html", meta = "15 briefs"),
  list(title = "Modular summary tables",
       desc  = "Every summarizable field of the seven RCRAInfo module master files, described variable by variable.",
       href  = "summary_tables/modular.html", meta = "7 modules"),
  list(title = "Biennial Report summary tables",
       desc  = "Twelve Biennial Report cycles, 2001 to 2023, summarized variable by variable.",
       href  = "summary_tables/biennial-report.html", meta = "12 cycles"),
  list(title = "State reporting reference",
       desc  = "How each state runs hazardous-waste reporting: system, requirements, and state-specific waste codes.",
       href  = "state-reporting.html", meta = "reference"),
  list(title = "Facility panels",
       desc  = "Balanced and unbalanced LQG / TSDF facility-cycle panels, plus facility-month compliance-evaluation, enforcement, and determined-violation panels (2015-2023).",
       href  = paste0(REPO, "/tree/main/code/modules/03_panels"), meta = "5 panels / code"))

# ---- tiny HTML helpers -------------------------------------------------------
esc <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;",  x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}
# markdown [text](url) -> external anchor, with a middot between adjacent links
md_links <- function(x) {
  x <- gsub("\\[([^]]+)\\]\\(([^)]+)\\)",
            '<a href="\\2" target="_blank" rel="noopener">\\1</a>', x)
  gsub("</a>\\s+<a ", "</a> <span class=\"dot\">&middot;</span> <a ", x)
}

# ==text== -> green marker, @@text@@ -> yellow marker (run after esc(), before md_links)
highlight <- function(x) {
  x <- gsub("==(.+?)==", '<mark class="hl-g">\\1</mark>', x, perl = TRUE)
  gsub("@@(.+?)@@",      '<mark class="hl-y">\\1</mark>', x, perl = TRUE)
}

is_ext  <- function(href) grepl("^https?://", href)
stamp   <- function() format(Sys.time(), "%B %e, %Y")

write_utf8 <- function(lines, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  con <- file(path, open = "wb"); on.exit(close(con))
  writeLines(enc2utf8(lines), con, useBytes = TRUE)
}

FAVICON <- paste0(
  "data:image/svg+xml,",
  "%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E",
  "%3Crect width='32' height='32' rx='3' fill='%23232D4B'/%3E",
  "%3Crect x='0' y='27' width='32' height='5' fill='%23E57200'/%3E",
  "%3Ctext x='16' y='22' font-family='Georgia,serif' font-size='19' ",
  "fill='white' text-anchor='middle'%3ER%3C/text%3E%3C/svg%3E")

FONT_LINKS <- paste0(
  "<link rel=\"preconnect\" href=\"https://fonts.googleapis.com\"/>\n",
  "<link rel=\"preconnect\" href=\"https://fonts.gstatic.com\" crossorigin/>\n",
  "<link rel=\"stylesheet\" href=\"https://fonts.googleapis.com/css2?",
  "family=Libre+Franklin:wght@300;400;500;600;700&family=Lora:wght@400;500;600;700&display=swap\"/>\n")

# `up` is the relative hop back to docs/ ("" for pages at the site root, "../"
# for the brief articles in docs/briefs/); every in-site href is prefixed by it.
head_html <- function(title, desc, up = "") paste0(
  "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n",
  "<meta charset=\"utf-8\"/>\n",
  "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"/>\n",
  "<title>", esc(title), "</title>\n",
  "<meta name=\"description\" content=\"", esc(desc), "\"/>\n",
  "<link rel=\"icon\" href=\"", FAVICON, "\"/>\n",
  FONT_LINKS,
  "<link rel=\"stylesheet\" href=\"", up, "assets/site.css\"/>\n",
  "</head>\n<body>\n")

# masthead + navigation (institutional data-portal chrome; no brand logo mark)
chrome <- function(active, up = "") {
  items <- list(
    c("index.html#pipeline",    "Pipeline"),
    c("index.html#data",        "Data"),
    c("index.html#outputs",     "Outputs"),
    c("briefs.html",            "Briefs"),
    c("state-reporting.html",   "State Reporting"))
  links <- vapply(items, function(it) {
    cls <- if (identical(it[2], active)) " class=\"on\"" else ""
    sprintf('<a href="%s%s"%s>%s</a>', up, it[1], cls, it[2])
  }, "")
  paste0(
    '<header class="masthead"><div class="wrap">',
    '<p class="eyebrow">Resource Conservation and Recovery Act</p>',
    '<h1 class="mast-title">RCRA Regulatory Data Infrastructure</h1>',
    '<p class="mast-sub">Facility-level data on hazardous waste, ',
    'assembled from public EPA sources.</p>',
    '</div></header>\n',
    '<nav class="mnav"><div class="wrap mnav-in">',
    paste(links, collapse = ""),
    '<a class="ext" href="', REPO, '" target="_blank" rel="noopener">Source</a>',
    '</div></nav>\n')
}

# horizontal UVA Batten lockup - official school artwork (resources/batten-logo.png,
# scraped from batten.virginia.edu, copied into docs/assets/ by copy_assets())
BATTEN_LOGO <- function(up = "") paste0(
  '<img class="batten" src="', up, 'assets/batten-logo.png" width="850" height="147" ',
  'alt="University of Virginia, Frank Batten School of Leadership and Public Policy"/>')

footer_html <- function(up = "") paste0(
  '<div class="footlogo"><div class="wrap footlogo-in">',
  BATTEN_LOGO(up),
  '<a class="footlogo-link" href="', REPO, '" target="_blank" rel="noopener">Replication package &nearr;</a>',
  '</div></div>\n',
  '<footer class="footbar"><div class="wrap">',
  '<p>All inputs are public U.S. federal data published by the EPA and in the public domain. ',
  'The pipeline downloads the current release of each dataset, so a fresh run reflects the latest EPA vintage.</p>',
  '<p class="footbar-meta">Code under the repository LICENSE &middot; ',
  '<a href="', REPO, '" target="_blank" rel="noopener">source and README</a> &middot; ',
  'built from the repository&rsquo;s own outputs &middot; generated ', stamp(), '</p>',
  '</div></footer>\n</body>\n</html>\n')

# ---- index.html sections -----------------------------------------------------
hero_html <- paste0(
  '<section class="hero"><div class="wrap"><div class="herocard">',
  '<h2 class="hero-h">Hazardous-waste regulation, assembled into research infrastructure.</h2>',
  '<p class="hero-lede">A reproducible R pipeline that turns public EPA data on RCRA compliance and ',
  'enforcement into analysis-ready facility panels, spanning 2001 to 2023.</p>',
  '<div class="cta">',
  '<a class="btn" href="#outputs">Browse the outputs</a>',
  '<a class="btn ghost" href="', REPO, '" target="_blank" rel="noopener">View the code &nearr;</a>',
  '</div></div></div></section>\n')

stats_html <- function() {
  cells <- vapply(STATS, function(s) paste0(
    '<div class="stat"><span class="num">', esc(s[1]),
    '</span><span class="lab">', esc(s[2]), '</span></div>'), "")
  paste0('<section class="stats"><div class="wrap stat-row">',
         paste(cells, collapse = ""), '</div></section>\n')
}

section_head <- function(h, sub) paste0(
  '<div class="sec-head"><h2>', esc(h), '</h2>',
  '<p class="sec-sub">', sub, '</p></div>')

pipeline_html <- function() {
  cols <- vapply(STAGES, function(s) paste0(
    '<div class="card stage"><span class="step">', esc(s[1]), '</span>',
    '<h3>', esc(s[2]), '</h3><p>', esc(s[3]), '</p></div>'), "")
  paste0(
    '<section class="sec gray" id="pipeline"><div class="wrap">',
    section_head("Four stages, one master script",
                 paste0("Every module runs in order from <code>code/master.R</code>, ",
                        "each in its own environment.")),
    '<div class="grid-4">', paste(cols, collapse = ""), '</div>',
    '</div></section>\n')
}

data_html <- function() {
  grp <- vapply(SOURCES, function(g) {
    rows <- vapply(g$items, function(it) paste0(
      '<li><div class="src-h"><a class="src-name" href="', it[4],
      '" target="_blank" rel="noopener">', esc(it[1]),
      '</a><span class="tag">', esc(it[2]), '</span></div>',
      '<p>', esc(it[3]), '</p></li>'), "")
    paste0('<div class="card srccard"><h3>', esc(g$group), '</h3><ul class="src-list">',
           paste(rows, collapse = ""), '</ul></div>')
  }, "")
  paste0(
    '<section class="sec" id="data"><div class="wrap">',
    section_head("Public EPA sources",
                 "Downloaded at run time. None are redistributed here."),
    '<div class="grid-3">', paste(grp, collapse = ""), '</div>',
    '</div></section>\n')
}

outputs_html <- function() {
  cards <- vapply(CARDS, function(c) {
    ext <- is_ext(c$href)
    arrow <- if (ext) "&nearr;" else "&rarr;"
    tgt <- if (ext) ' target="_blank" rel="noopener"' else ""
    paste0(
      '<a class="card out" href="', c$href, '"', tgt, '>',
      '<div class="card-top"><span class="card-meta">', esc(c$meta),
      '</span><span class="arrow">', arrow, '</span></div>',
      '<h3>', esc(c$title), '</h3><p>', esc(c$desc), '</p></a>')
  }, "")
  paste0(
    '<section class="sec gray" id="outputs"><div class="wrap">',
    section_head("What the pipeline produces",
                 paste0("Summary tables and panels ship with the repository; ",
                        "the raw and master data rebuild from code.")),
    '<div class="grid-cards">', paste(cards, collapse = ""), '</div>',
    '</div></section>\n')
}

about_html <- paste0(
  '<section class="sec about"><div class="wrap">',
  '<h2 class="about-h">About the data</h2>',
  '<p class="about-p">All data are public U.S. federal government data published by the EPA. ',
  'The raw files are not committed to the repository because of their size; they are fully ',
  'reproducible by running the code, which downloads the current release of each dataset. ',
  'Because EPA refreshes these datasets on rolling schedules, a later run downloads ',
  'a newer vintage than the one documented in the replication README.</p>',
  '</div></section>\n')

build_index <- function() {
  html <- paste0(
    head_html("RCRA Regulatory Data Infrastructure",
              "A reproducible R pipeline turning public EPA hazardous-waste data into analysis-ready facility panels, 2001-2023."),
    chrome(NA), hero_html, stats_html(), pipeline_html(), data_html(),
    outputs_html(), about_html, footer_html())
  write_utf8(html, file.path(DOCS, "index.html"))
  cat("Wrote", file.path(DOCS, "index.html"), "\n")
}

# ---- institutional briefs ----------------------------------------------------
# Source of truth is docs/institutional_briefs/*.md; this renders each one into
# docs/briefs/<stem>.html plus a docs/briefs.html contents page. Reading order is
# the list below, which also supplies the card blurbs and the previous/next rail.
BRIEF_DIR <- file.path(DOCS, "institutional_briefs")
BRIEFS <- list(
  c("00_overview",                 "Institutional overview",
    "The statute, what makes a waste hazardous, how oversight escalates, and the map from program function to data source."),
  c("01_biennial_report",          "The Biennial Report",
    "Who files the every-other-year waste report, what the tonnage figures mean, and where the states complicate the picture."),
  c("02_generators_and_handlers",  "Generators, handlers, and TSDFs",
    "The regulated universe, the generator size categories that decide which rules apply, and the facilities at the end of the chain."),
  c("03_compliance_and_enforcement","Compliance monitoring and enforcement",
    "Evaluations, violations, significant noncompliance, and the ladder of enforcement responses."),
  c("04_state_authorization",      "State authorization and federalism",
    "Why a federal program run by the states makes the same activity appear differently across state lines."),
  c("05_corrective_action",        "Corrective action",
    "The cleanup arm of the program and why its record is a series of events rather than a single entry."),
  c("06_permitting_and_closure",   "Permitting, closure, and post-closure",
    "The permit a treatment or disposal facility needs, and what must happen when a unit stops operating."),
  c("07_financial_assurance",      "Financial assurance",
    "The requirement that a facility prove in advance it can pay to close and to care for the site afterwards."),
  c("08_waste_import_export",      "Waste import and export",
    "The consents and notices that govern hazardous waste crossing a national border."),
  c("09_facility_identifiers",     "Facility identifiers",
    "The several identifiers one physical site carries, and the crosswalk that joins them."),
  c("10_epa_forms",                "The three EPA forms",
    "Where the records come from, and which Biennial Report fields EPA computes rather than collects."),
  c("11_manifests_and_shipment_tracking", "Manifests and shipment tracking",
    "The document that follows each shipment of waste, and why the national electronic record of it only begins in 2018."),
  c("12_waste_codes_and_management_methods", "Waste codes and management methods",
    "The vocabulary the records use for what a waste is, where it came from, and what was done with it."),
  c("13_universal_waste_used_oil_and_recycling", "Universal waste, used oil, and recycling",
    "The lighter regimes that sit inside the program, and the facility roles they put into the panels."),
  c("14_regulatory_citations",     "Regulatory citations",
    "How a violation points at the requirement it rests on, and why the state share of that record says less."))

brief_title <- function(stem) {
  hit <- Filter(function(b) identical(b[1], stem), BRIEFS)
  if (length(hit)) hit[[1]][2] else stem
}

# [text](href) with in-site rules: a sibling brief keeps the reader on the site,
# a repo-relative path resolves to GitHub, anything http opens in a new tab.
brief_links <- function(x) {
  m <- gregexpr("\\[([^]]+)\\]\\(([^)]+)\\)", x, perl = TRUE)
  hits <- regmatches(x, m)[[1]]
  if (!length(hits)) return(x)
  repl <- vapply(hits, function(h) {
    txt  <- sub("^\\[([^]]+)\\]\\(.*$", "\\1", h)
    href <- sub("^.*\\]\\(([^)]+)\\)$", "\\1", h)
    if (grepl("^https?://", href))
      return(sprintf('<a href="%s" target="_blank" rel="noopener">%s</a>', href, txt))
    if (grepl("^[0-9]{2}_.*\\.md$", href)) {                 # sibling brief
      stem <- sub("\\.md$", "", href)
      if (grepl("\\.md$", txt)) txt <- brief_title(stem)     # filename as text reads badly
      return(sprintf('<a href="%s.html">%s</a>', stem, txt))
    }
    if (grepl("^\\.\\./\\.\\./", href))                      # path back into the repo
      return(sprintf('<a href="%s/blob/main/%s" target="_blank" rel="noopener">%s</a>',
                     REPO, sub("^(\\.\\./)+", "", href), txt))
    sprintf('<a href="%s">%s</a>', href, txt)
  }, "")
  regmatches(x, m)[[1]] <- repl
  x
}

# esc -> highlight marks -> inline code -> links, in that order: the marks and the
# backticks are written in the markdown, so they must survive escaping untouched.
inline_md <- function(x) {
  x <- highlight(esc(x))
  x <- gsub("`([^`]+)`", "<code>\\1</code>", x, perl = TRUE)
  brief_links(x)
}

slugify <- function(x) {
  s <- tolower(gsub("[^A-Za-z0-9]+", "-", x))
  gsub("^-|-$", "", s)
}

# a deliberately small markdown subset: the briefs use H1, H2, paragraphs, one
# pipe table, links, inline code, and the == / @@ highlight marks. Nothing else.
render_brief <- function(lines) {
  out <- character(0); heads <- character(0); htext <- character(0)
  para <- character(0)
  flush_para <- function() {
    if (length(para)) {
      out <<- c(out, paste0("<p>", inline_md(paste(para, collapse = " ")), "</p>"))
      para <<- character(0)
    }
  }
  i <- 1L
  while (i <= length(lines)) {
    ln <- lines[i]
    if (grepl("^\\s*$", ln)) { flush_para(); i <- i + 1L; next }
    if (grepl("^# ", ln))    { i <- i + 1L; next }            # H1 becomes the page title
    if (grepl("^## ", ln)) {
      flush_para()
      h <- sub("^## ", "", ln); id <- slugify(h)
      heads <- c(heads, id); htext <- c(htext, h)
      out <- c(out, sprintf('<h2 id="%s">%s</h2>', id, inline_md(h)))
      i <- i + 1L; next
    }
    if (grepl("^\\|", ln)) {                                   # pipe table
      flush_para()
      blk <- character(0)
      while (i <= length(lines) && grepl("^\\|", lines[i])) { blk <- c(blk, lines[i]); i <- i + 1L }
      cells <- lapply(blk, split_cells)
      cells <- cells[!vapply(cells, function(r) all(grepl("^:?-+:?$", r)), TRUE)]
      if (length(cells)) {
        th <- paste0("<th>", vapply(cells[[1]], inline_md, ""), "</th>", collapse = "")
        tr <- vapply(cells[-1], function(r)
          paste0("<tr>", paste0("<td>", vapply(r, inline_md, ""), "</td>", collapse = ""), "</tr>"), "")
        out <- c(out, paste0("<table><thead><tr>", th, "</tr></thead><tbody>",
                             paste(tr, collapse = ""), "</tbody></table>"))
      }
      next
    }
    if (grepl("^[-*] ", ln)) {                                 # unordered list
      flush_para()
      items <- character(0)
      while (i <= length(lines) && (grepl("^[-*] ", lines[i]) || grepl("^\\s+\\S", lines[i]))) {
        if (grepl("^[-*] ", lines[i])) items <- c(items, sub("^[-*] ", "", lines[i]))
        else items[length(items)] <- paste(items[length(items)], trimws(lines[i]))
        i <- i + 1L
      }
      out <- c(out, paste0("<ul>", paste0("<li>", vapply(items, inline_md, ""), "</li>",
                                          collapse = ""), "</ul>"))
      next
    }
    para <- c(para, ln); i <- i + 1L
  }
  flush_para()
  list(body = paste(out, collapse = "\n"), heads = heads, htext = htext)
}

brief_page <- function(idx) {
  stem <- BRIEFS[[idx]][1]; title <- BRIEFS[[idx]][2]; blurb <- BRIEFS[[idx]][3]
  src  <- file.path(BRIEF_DIR, paste0(stem, ".md"))
  if (!file.exists(src)) { warning("missing ", src, call. = FALSE); return(invisible(NULL)) }
  md <- readLines(src, warn = FALSE, encoding = "UTF-8")
  r  <- render_brief(md)

  toc <- ""
  if (length(r$heads)) {
    links <- sprintf('<a href="#%s">%s</a>', r$heads, esc(r$htext))
    toc <- paste0('<aside class="toc"><h4>On this page</h4>', paste(links, collapse = ""), '</aside>')
  }

  prv <- if (idx > 1) BRIEFS[[idx - 1]] else NULL
  nxt <- if (idx < length(BRIEFS)) BRIEFS[[idx + 1]] else NULL
  navp <- paste0(
    '<nav class="artnav">',
    if (!is.null(prv)) sprintf('<a class="pv" href="%s.html"><span class="dir">&larr; Previous</span>%s</a>',
                               prv[1], esc(prv[2])) else "",
    if (!is.null(nxt)) sprintf('<a class="nx" href="%s.html"><span class="dir">Next &rarr;</span>%s</a>',
                               nxt[1], esc(nxt[2])) else "",
    '</nav>')

  html <- paste0(
    head_html(paste0(title, " - RCRA Regulatory Data Infrastructure"), blurb, up = "../"),
    chrome("Briefs", up = "../"),
    '<section class="sec plainhead"><div class="wrap">',
    '<p class="crumb"><a href="../index.html">Overview</a> / <a href="../briefs.html">Briefs</a> / ',
    esc(title), '</p>',
    '<h2 class="page-h">', esc(title), '</h2>',
    '<p class="page-lede">', esc(blurb), '</p>',
    '</div></section>\n',
    '<section class="brief"><div class="wrap"><div class="artgrid">',
    '<article class="art">', r$body, navp, '</article>',
    toc,
    '</div></div></section>\n',
    footer_html(up = "../"))
  write_utf8(html, file.path(DOCS, "briefs", paste0(stem, ".html")))
  invisible(stem)
}

build_briefs <- function() {
  n <- 0L
  for (i in seq_along(BRIEFS)) if (!is.null(brief_page(i))) n <- n + 1L

  cards <- vapply(seq_along(BRIEFS), function(i) {
    b <- BRIEFS[[i]]
    paste0('<a class="card bcard" href="briefs/', b[1], '.html">',
           '<span class="bnum">Brief ', sub("_.*$", "", b[1]), '</span>',
           '<h3>', esc(b[2]), '</h3><p>', esc(b[3]), '</p></a>')
  }, "")

  html <- paste0(
    head_html("Institutional briefs - RCRA Regulatory Data Infrastructure",
              "Background on the federal hazardous-waste program, written so the administrative records in this project can be read correctly."),
    chrome("Briefs"),
    '<section class="sec plainhead"><div class="wrap">',
    '<p class="crumb"><a href="index.html">Overview</a> / Briefs</p>',
    '<h2 class="page-h">Institutional briefs</h2>',
    '<p class="page-lede">The data in this project are administrative records produced by a ',
    'regulatory program, so a column only means what the rule behind it says it means. ',
    'These briefs record those rules, and each one ends by spelling out what they imply for ',
    'the tables and panels built here.</p>',
    '<p class="hl-key">Highlights mark <span class="hl-g">the rule or definition that a variable ',
    'rests on</span> and <span class="hl-y">the exceptions and cautions that limit how far a ',
    'reading can be pushed</span>.</p>',
    '</div></section>\n',
    '<section class="sec gray"><div class="wrap">',
    '<div class="briefgrid">', paste(cards, collapse = ""), '</div>',
    '<p class="note">Written from public EPA program materials and from the state-by-state ',
    'reporting reference. They are background, not a legal reference, and are meant to be ',
    'revised as the project grows. The markdown sources live in ',
    '<code>docs/institutional_briefs/</code>.</p>',
    '</div></section>\n',
    footer_html())
  write_utf8(html, file.path(DOCS, "briefs.html"))
  cat("Wrote", file.path(DOCS, "briefs.html"), " (", n, "briefs )\n")
}

# ---- state-reporting.html ----------------------------------------------------
STATE_HEADERS <- c("State &amp; reporting system", "Reporting requirements",
                   "State-specific waste codes", "Agency &amp; sources")

split_cells <- function(line) {
  s <- sub("^\\s*\\|", "", line); s <- sub("\\|\\s*$", "", s)
  trimws(strsplit(s, "|", fixed = TRUE)[[1]])
}

state_cell1 <- function(txt) {
  m <- regexpr(" (Uses|Do not use)", txt)
  if (m > 0) {
    name <- substr(txt, 1, m - 1)
    sys  <- substr(txt, m + 1, nchar(txt))
    # yellow-mark the states that break the "Uses RCRAInfo, paper accepted" baseline
    cls  <- if (grepl("not accepted|Do not use", sys)) "sys hl-y" else "sys"
    paste0("<strong>", esc(name), "</strong><span class=\"", cls, "\">", esc(sys), "</span>")
  } else paste0("<strong>", esc(txt), "</strong>")
}

# NOTE: docs/state-reporting.html has since been revised by hand and is ahead of
# resources/table.md. The live page splits each requirement into its own <p class="rq">,
# carries one <span class="sys"> per reporting system, marks state names that break the
# baseline, and uses <ul class="wc"> for waste-code lists; none of that round-trips back
# into the flat markdown table this function reads. Rebuilding from TABLE_MD would
# therefore throw those revisions away, so the page is not part of a default build and
# has to be asked for by name AND confirmed:
#
#   Rscript code/utils/build_site.R state force
#
# Before ever passing "force", bring resources/table.md up to the live page's content and
# teach this function to emit that richer markup; otherwise the page loses work.
build_state <- function() {
  if (!file.exists(TABLE_MD)) { warning("missing ", TABLE_MD, "; skipping state page"); return(invisible()) }
  raw  <- readLines(TABLE_MD, warn = FALSE, encoding = "UTF-8")
  rows <- raw[grepl("^\\s*\\|", raw)]
  rows <- rows[!grepl("^\\s*\\|[-\\s|]+\\|\\s*$", rows)]   # drop the --- separator
  if (length(rows)) rows <- rows[-1]                       # drop the header row
  body <- lapply(rows, split_cells)
  body <- Filter(function(r) length(r) >= 2, body)
  n    <- length(body)

  head_cells <- paste0("<th>", STATE_HEADERS, "</th>", collapse = "")
  trs <- vapply(body, function(r) {
    c1 <- state_cell1(r[1])
    rest <- vapply(seq_along(STATE_HEADERS)[-1], function(i)
      paste0("<td>", if (i <= length(r)) md_links(highlight(esc(r[i]))) else "", "</td>"), "")
    paste0("<tr><td class=\"st\">", c1, "</td>", paste(rest, collapse = ""), "</tr>")
  }, "")

  script <- paste0(
    "<script>\n",
    "const q=document.getElementById('q'),rows=[...document.querySelectorAll('tbody tr')],",
    "cnt=document.getElementById('shown');\n",
    "q.addEventListener('input',()=>{const t=q.value.toLowerCase();let s=0;\n",
    "rows.forEach(r=>{const hit=r.textContent.toLowerCase().includes(t);r.hidden=!hit;if(hit)s++;});\n",
    "cnt.textContent=s;});\n</script>\n")

  html <- paste0(
    head_html("State reporting reference - RCRA Regulatory Data Infrastructure",
              "How each U.S. state runs hazardous-waste reporting under RCRA: reporting system, requirements, and state-specific waste codes."),
    chrome("State Reporting"),   # must match the nav label exactly, or nothing marks active
    '<section class="sec plainhead"><div class="wrap">',
    '<p class="crumb"><a href="index.html">Overview</a> / State reporting</p>',
    '<h2 class="page-h">State reporting reference</h2>',
    '<p class="page-lede">How each state runs hazardous-waste reporting under RCRA, ',
    'which system it uses, what it requires, and the waste codes it adds beyond the federal list.</p>',
    '<div class="searchbar">',
    '<input id="q" type="search" placeholder="Filter by state, agency, waste code, keyword..." autocomplete="off"/>',
    '<span class="count"><span id="shown">', n, '</span> of ', n, ' states</span>',
    '</div>',
    '<p class="hl-key">Highlights mark <span class="hl-g">state reporting requirements</span> and ',
    '<span class="hl-y">non-standard reporting systems or notable exceptions</span>.</p>',
    '</div></section>\n',
    '<section class="sec gray"><div class="wrap">',
    '<div class="tablewrap"><table class="states">',
    '<thead><tr>', head_cells, '</tr></thead><tbody>',
    paste(trs, collapse = ""), '</tbody></table></div>',
    '<p class="note">Reference compiled from state environmental-agency pages and secondary summaries; ',
    'currently ', n, ' states. Always confirm current requirements with the state agency linked in each row.</p>',
    '</div></section>\n',
    script, footer_html())
  write_utf8(html, file.path(DOCS, "state-reporting.html"))
  cat("Wrote", file.path(DOCS, "state-reporting.html"), " (", n, "states )\n")
}

# ---- copy the compiled summary-table pages into the site --------------------
copy_summaries <- function() {
  dst <- file.path(DOCS, "summary_tables"); dir.create(dst, recursive = TRUE, showWarnings = FALSE)
  pairs <- list(
    c("Modular Summary Tables.html",          "modular.html"),
    c("Biennial Report Summary Tables.html",  "biennial-report.html"))
  for (p in pairs) {
    src <- file.path(SUMMARY_DIR, p[1])
    if (file.exists(src)) {
      file.copy(src, file.path(dst, p[2]), overwrite = TRUE)
      cat("Copied", p[1], "->", file.path(dst, p[2]), "\n")
    } else {
      warning("missing ", src, "; run code/utils/summary_tables_to_html.R first", call. = FALSE)
    }
  }
}

# ---- copy the bundled Batten logo into the site -----------------------------
copy_assets <- function() {
  dir.create(ASSETS, recursive = TRUE, showWarnings = FALSE)
  src <- "resources/batten-logo.png"
  if (file.exists(src)) {
    file.copy(src, file.path(ASSETS, "batten-logo.png"), overwrite = TRUE)
    cat("Copied", src, "->", file.path(ASSETS, "batten-logo.png"), "\n")
  } else warning("missing ", src, "; the footer logo will 404", call. = FALSE)
}

# ---- shared stylesheet (serif display + sans body; institutional light theme) ----
SITE_CSS <- '
:root{
  --ink:#1a1a1a; --muted:#5b6470; --faint:#7b838d;
  --navy:#232D4B; --navy-2:#33406a; --orange:#E57200;
  --bar:#1e1e1e; --gray:#dce2e2; --gray-2:#eef1f1; --line:#d3d8d8; --card:#ffffff;
  --max:1120px;
  --sans:"Libre Franklin",-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
  --serif:"Lora",Georgia,"Times New Roman",serif;
}
*{box-sizing:border-box;}
html{scroll-padding-top:64px;}
@media (prefers-reduced-motion:no-preference){html{scroll-behavior:smooth;}}
body{margin:0;background:var(--card);color:var(--ink);font-family:var(--sans);
  font-size:17px;line-height:1.6;-webkit-font-smoothing:antialiased;text-rendering:optimizeLegibility;}
.wrap{max-width:var(--max);margin:0 auto;padding:0 32px;}
a{color:var(--navy);text-decoration:underline;text-underline-offset:2px;}
a:hover{color:var(--orange);}
h1,h2,h3{font-family:var(--serif);font-weight:600;line-height:1.2;color:var(--ink);}
code{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:.86em;
  background:var(--gray-2);border:1px solid var(--line);border-radius:3px;padding:.06em .34em;}

/* masthead */
.masthead{background:var(--gray-2);border-bottom:1px solid var(--line);padding:30px 0 24px;}
.eyebrow{margin:0 0 8px;font-size:12px;letter-spacing:.11em;text-transform:uppercase;
  color:var(--navy);font-weight:600;font-family:var(--sans);}
.mast-title{margin:0;font-size:clamp(28px,4vw,40px);font-weight:600;letter-spacing:-.01em;}
.mast-sub{margin:8px 0 0;font-family:var(--sans);color:var(--muted);font-size:16px;max-width:60ch;}

/* nav */
.mnav{background:var(--card);border-bottom:1px solid var(--line);position:sticky;top:0;z-index:20;}
.mnav-in{display:flex;gap:0 28px;align-items:center;min-height:52px;flex-wrap:wrap;}
.mnav a{font-family:var(--sans);font-size:14.5px;color:var(--ink);text-decoration:none;
  white-space:nowrap;padding:14px 0;border-bottom:2px solid transparent;}
.mnav a:hover{color:var(--navy);}
.mnav a.on{border-bottom-color:var(--orange);}
.mnav a.ext{margin-left:auto;color:var(--muted);}
.mnav a.ext::after{content:"\\2197";margin-left:2px;}

/* hero */
.hero{background:var(--navy);padding:60px 0;}
.herocard{background:var(--card);border-top:4px solid var(--orange);padding:40px 44px 42px;max-width:720px;}
.hero-h{margin:0 0 16px;font-size:clamp(26px,3.6vw,38px);font-weight:600;line-height:1.18;}
.hero-lede{margin:0 0 26px;font-family:var(--sans);font-size:18px;color:var(--muted);max-width:56ch;}
.cta{display:flex;gap:12px;flex-wrap:wrap;}
.btn{display:inline-block;font-family:var(--sans);font-size:15px;font-weight:600;
  padding:11px 22px;border-radius:3px;background:var(--navy);color:#fff;
  text-decoration:none;border:1px solid var(--navy);}
.btn:hover{background:var(--navy-2);color:#fff;}
.btn.ghost{background:transparent;color:var(--navy);}
.btn.ghost:hover{border-color:var(--orange);color:var(--orange);}

/* stats */
.stats{background:var(--card);border-bottom:1px solid var(--line);}
.stat-row{display:flex;flex-wrap:wrap;padding:30px 32px;}
.stat{flex:1 1 150px;display:flex;flex-direction:column;gap:5px;
  padding:2px 0 2px 22px;border-left:1px solid var(--line);}
.stat:first-child{border-left:0;padding-left:0;}
.num{font-family:var(--serif);font-size:clamp(28px,3.6vw,38px);font-weight:600;color:var(--navy);}
.lab{font-family:var(--sans);font-size:12px;letter-spacing:.04em;text-transform:uppercase;color:var(--faint);}

/* sections */
.sec{padding:64px 0;}
.sec.gray{background:var(--gray);border-top:1px solid var(--line);border-bottom:1px solid var(--line);}
.sec-head{margin-bottom:34px;max-width:64ch;}
.sec-head h2{margin:0 0 8px;font-size:clamp(22px,3vw,30px);}
.sec-sub{margin:0;font-family:var(--sans);color:var(--muted);font-size:16px;}
.sec-sub code{font-size:14px;}

/* cards */
.card{background:var(--card);border:1px solid var(--line);padding:24px 24px 26px;}
.grid-4{display:grid;grid-template-columns:repeat(4,1fr);gap:18px;}
.grid-3{display:grid;grid-template-columns:repeat(3,1fr);gap:18px;align-items:start;}
.grid-cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:18px;}
.card h3{margin:0 0 10px;font-size:19px;font-weight:600;}
.stage .step{font-family:var(--sans);font-size:12.5px;font-weight:700;color:var(--orange);letter-spacing:.05em;}
.stage h3{margin:10px 0 8px;}
.stage p,.srccard p,.out p{font-family:var(--sans);font-size:14.5px;color:var(--muted);margin:0;}

/* data source cards */
.srccard h3{font-size:14px;letter-spacing:.05em;text-transform:uppercase;color:var(--navy);
  font-family:var(--sans);font-weight:700;padding-bottom:12px;margin-bottom:16px;border-bottom:1px solid var(--line);}
.src-list{list-style:none;margin:0;padding:0;display:flex;flex-direction:column;gap:16px;}
.src-h{display:flex;align-items:baseline;justify-content:space-between;gap:10px;}
.src-name{font-family:var(--sans);font-weight:600;font-size:15.5px;color:var(--ink);}
a.src-name{text-decoration:underline;text-decoration-color:var(--line);text-decoration-thickness:1px;
  text-underline-offset:3px;}
a.src-name:hover{color:var(--orange);text-decoration-color:var(--orange);}
.tag{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:11px;color:var(--faint);white-space:nowrap;}
.src-list p{margin:3px 0 0;}

/* output cards */
.out{display:flex;flex-direction:column;text-decoration:none;transition:border-color .15s;}
.out:hover{border-color:var(--navy);}
.card-top{display:flex;justify-content:space-between;align-items:center;margin-bottom:14px;}
.card-meta{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:11px;color:var(--faint);
  text-transform:uppercase;letter-spacing:.05em;}
.arrow{color:var(--navy);font-size:18px;}
.out:hover .arrow{color:var(--orange);}
.out h3{color:var(--ink);}

/* about (big serif statement) */
.sec.about{background:var(--card);}
.about-h{margin:0 0 18px;font-size:clamp(24px,3.4vw,34px);text-transform:uppercase;letter-spacing:.01em;}
.about-p{font-family:var(--sans);color:var(--muted);font-size:16px;max-width:80ch;margin:0;}

/* sub-page head + search */
.plainhead{padding:44px 0 34px;}
.crumb{margin:0 0 14px;font-family:var(--sans);font-size:14px;color:var(--muted);}
.page-h{margin:0 0 12px;font-size:clamp(26px,3.6vw,38px);}
.page-lede{margin:0;font-family:var(--sans);font-size:17px;color:var(--muted);max-width:70ch;}
.searchbar{display:flex;align-items:center;gap:16px;flex-wrap:wrap;margin-top:24px;}
#q{flex:1 1 320px;max-width:460px;padding:12px 15px;font-family:var(--sans);font-size:15px;
  color:var(--ink);background:var(--card);border:1px solid var(--line);border-radius:3px;}
#q:focus{outline:none;border-color:var(--navy);}
.count{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:13px;color:var(--faint);}

/* state table */
.tablewrap{overflow-x:auto;border:1px solid var(--line);background:var(--card);}
table.states{border-collapse:collapse;width:100%;font-family:var(--sans);font-size:14px;min-width:840px;}
table.states thead th{background:var(--gray-2);text-align:left;font-size:12px;letter-spacing:.04em;
  text-transform:uppercase;color:var(--muted);font-weight:700;padding:14px 16px;border-bottom:1px solid var(--line);}
table.states td{padding:16px;border-bottom:1px solid var(--line);vertical-align:top;color:var(--ink);}
table.states tr:last-child td{border-bottom:0;}
table.states tbody tr:hover td{background:var(--gray-2);}
td.st{min-width:190px;}
td.st strong{display:block;font-size:15px;font-weight:600;margin-bottom:5px;color:var(--ink);}
td.st .sys{display:block;width:fit-content;font-size:12.5px;color:var(--faint);margin:0 0 3px;}
td.st .sys.hl-y{color:var(--ink);padding:.14em .45em;border-radius:.16em;
  background:rgba(255,213,102,.6);}
td p.rq{margin:0 0 9px;}
td p.rq:last-child{margin-bottom:0;}
td.agency a{display:block;width:fit-content;margin:0 0 7px;}
td.agency a:last-child{margin-bottom:0;}
ul.wc{list-style:none;margin:0 0 9px;padding:0;}
ul.wc:last-child{margin-bottom:0;}
ul.wc li{margin:0 0 3px;padding-left:14px;text-indent:-14px;}
ul.wc li::before{content:"\\2013\\00a0";color:var(--faint);}
.wc-h{display:block;text-decoration:underline;text-underline-offset:2px;margin:0 0 4px;}
.note{font-family:var(--sans);font-size:13px;color:var(--faint);margin:20px 0 0;max-width:74ch;}

/* highlighter marks - full-height translucent marker, as in the source document */
.hl-g,.hl-y{color:inherit;-webkit-box-decoration-break:clone;box-decoration-break:clone;
  padding:.08em .18em;border-radius:.14em;}
.hl-g{background:rgba(150,205,140,.55);}
.hl-y{background:rgba(255,213,102,.6);}
.hl-key{font-family:var(--sans);font-size:13px;color:var(--muted);margin:16px 0 0;}
.hl-key .hl-g,.hl-key .hl-y{font-weight:500;color:var(--ink);}

/* institutional briefs - index cards */
.briefgrid{display:grid;grid-template-columns:repeat(auto-fit,minmax(290px,1fr));gap:18px;}
.bcard{background:var(--card);border:1px solid var(--line);border-left:3px solid var(--orange);
  padding:22px 24px 24px;text-decoration:none;display:flex;flex-direction:column;
  transition:border-color .15s,box-shadow .15s;}
.bcard:hover{border-color:var(--navy);border-left-color:var(--orange);box-shadow:0 1px 0 var(--line);}
.bcard .bnum{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:11px;
  letter-spacing:.06em;text-transform:uppercase;color:var(--faint);}
.bcard h3{margin:9px 0 8px;font-size:18px;color:var(--ink);}
.bcard p{margin:0;font-family:var(--sans);font-size:14.5px;color:var(--muted);}

/* institutional briefs - article page */
.brief{padding:40px 0 76px;}
.artgrid{display:grid;grid-template-columns:minmax(0,1fr) 232px;gap:52px;align-items:start;}
article.art{max-width:72ch;}
article.art h2{margin:44px 0 15px;font-size:clamp(20px,2.6vw,26px);
  padding-bottom:9px;border-bottom:2px solid var(--orange);}
article.art > h2:first-child{margin-top:0;}
article.art p{margin:0 0 18px;font-family:var(--sans);font-size:16.5px;line-height:1.68;}
article.art ul{margin:0 0 18px;padding-left:22px;font-family:var(--sans);font-size:16.5px;line-height:1.68;}
article.art li{margin:0 0 7px;}
article.art code{font-size:.84em;}
article.art table{border-collapse:collapse;width:100%;margin:4px 0 26px;
  font-family:var(--sans);font-size:14px;}
article.art thead th{background:var(--gray-2);text-align:left;font-size:11.5px;letter-spacing:.04em;
  text-transform:uppercase;color:var(--muted);font-weight:700;padding:12px 14px;
  border-bottom:1px solid var(--line);}
article.art tbody td{padding:12px 14px;border-bottom:1px solid var(--line);vertical-align:top;}
article.art tbody tr:last-child td{border-bottom:0;}
article.art table{border:1px solid var(--line);}

/* in-page contents rail */
aside.toc{position:sticky;top:74px;font-family:var(--sans);}
aside.toc h4{margin:0 0 10px;font-family:var(--sans);font-size:11.5px;letter-spacing:.08em;
  text-transform:uppercase;color:var(--faint);font-weight:700;}
aside.toc a{display:block;font-size:13.5px;line-height:1.4;color:var(--muted);text-decoration:none;
  padding:6px 0 6px 13px;border-left:2px solid var(--line);}
aside.toc a:hover{color:var(--navy);border-left-color:var(--orange);}

/* previous / next */
.artnav{display:flex;justify-content:space-between;gap:18px;flex-wrap:wrap;
  margin-top:52px;padding-top:24px;border-top:1px solid var(--line);}
.artnav a{font-family:var(--sans);font-size:14px;text-decoration:none;color:var(--navy);max-width:44ch;}
.artnav a:hover{color:var(--orange);}
.artnav .dir{display:block;font-size:11px;letter-spacing:.07em;text-transform:uppercase;
  color:var(--faint);margin-bottom:3px;}
.artnav .nx{text-align:right;margin-left:auto;}

/* footer */
.footlogo{background:var(--card);border-top:1px solid var(--line);}
.wrap.footlogo-in{display:flex;align-items:center;justify-content:space-between;gap:22px 40px;
  flex-wrap:wrap;padding:38px 32px;}
.batten{width:min(300px,100%);height:auto;flex-shrink:0;}
.footlogo-link{font-family:var(--sans);font-size:13.5px;color:var(--navy);}
.footbar{background:var(--bar);color:#c3c8cf;padding:34px 0;}
.footbar p{margin:0 0 10px;font-family:var(--sans);font-size:13.5px;line-height:1.55;max-width:80ch;}
.footbar-meta{color:#8b929c;font-size:12.5px;}
.footbar a{color:#dfe2e7;}
.footbar a:hover{color:#fff;}

@media (max-width:900px){
  .grid-4{grid-template-columns:repeat(2,1fr);}
  .grid-3{grid-template-columns:1fr;}
  .artgrid{grid-template-columns:1fr;gap:0;}
  aside.toc{display:none;}
}
@media (max-width:640px){
  .wrap.footlogo-in{flex-direction:column;align-items:center;text-align:center;padding:30px 32px;}
}
@media (max-width:560px){
  .wrap{padding:0 20px;}
  .wrap.footlogo-in{padding:30px 20px;}
  .grid-4{grid-template-columns:1fr;}
  .herocard{padding:30px 24px;}
  .mnav a.ext{display:none;}
}
'

write_css <- function() {
  write_utf8(SITE_CSS, file.path(ASSETS, "site.css"))
  cat("Wrote", file.path(ASSETS, "site.css"), "\n")
}

# ---- CLI ---------------------------------------------------------------------
args <- tolower(commandArgs(trailingOnly = TRUE))
dir.create(DOCS, showWarnings = FALSE)
write_css()
copy_assets()
if (!length(args) || "index"  %in% args) build_index()
if (!length(args) || "briefs" %in% args) build_briefs()
if (!length(args))                       copy_summaries()
if ("state" %in% args) {
  if ("force" %in% args) build_state()
  else cat("Skipped state-reporting.html: the live page is ahead of ", TABLE_MD,
           ".\n  Pass 'state force' only after reconciling the two (see the note above build_state).\n", sep = "")
}
cat("Site ready under ", DOCS, "/\n", sep = "")
