# =============================================================================
# FILE:     build_site.R
# PURPOSE:  Assemble the public project website under docs/ from artifacts the
#           repository already holds. A convenience tool, not part of the
#           pipeline; master.R never runs it.
# INPUTS:   output/summary_tables/Modular Summary Tables.html and Biennial Report
#           Summary Tables.html; resources/table.md; resources/batten-logo.png
# OUTPUTS:  docs/index.html, docs/state-reporting.html,
#           docs/summary-tables/*.html, docs/assets/site.css
# AUTHOR:   Jason Ye
# CREATED:  2026-07-16
# UPDATED:  2026-07-16
# =============================================================================

# Build the public project website into docs/ (published by GitHub Pages).
#
#   docs/index.html            front door: overview, pipeline, data, outputs
#   docs/state-reporting.html  searchable state-by-state RCRA reporting reference
#                              (rendered from resources/table.md)
#   docs/summary-tables/       the two compiled summary-table pages, copied in
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
#   Rscript code/utils/build_site.R          # build the whole site
#   Rscript code/utils/build_site.R state    # only the state-reporting page
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
  c("9",     "EPA data sources"),
  c("7",     "RCRAInfo modules"),
  c("12",    "Biennial cycles"),
  c("4",     "Facility panels"),
  c("~60",   "GB, reproducible"))

STAGES <- list(
  c("01", "Download",
    "Nine EPA datasets pulled at run time from ECHO, RCRAInfo / HWIP, and five supplementary programs, each with its data dictionary scraped alongside."),
  c("02", "Master files",
    "One analysis-ready CSV per module, each central table joined to its dimension tables with identifiers preserved verbatim."),
  c("03", "Panels",
    "Facility panels built from the master files and the Biennial Report, each linked to EPA Facility Registry Service IDs."),
  c("04", "Summary tables",
    "Every module's central table summarized variable by variable: categorical frequencies, quantitative ranges, and Y/N indicators."))

# grouped data sources: label, tag, one-line description
SOURCES <- list(
  list(group = "Core RCRA", items = list(
    c("ECHO RCRA Pipeline",  "EPA / ECHO",   "Compliance-monitoring activities with linked violations and enforcement actions."),
    c("ECHO RCRAInfo",       "EPA / ECHO",   "Compliance and enforcement extract for hazardous-waste sites."),
    c("RCRAInfo CSV exports","EPA / HWIP",   "Complete module tables: Biennial Report, Corrective Action, CME, e-Manifest, Financial Assurance, Handler, Permitting, WIETS."))),
  list(group = "Supplementary facility datasets", items = list(
    c("TRI",   "EPA", "Toxics Release Inventory Basic Plus files, 2011-2024."),
    c("NEI",   "EPA", "National Emissions Inventory point-source extracts, 2011-2022."),
    c("GHGRP", "EPA", "Greenhouse Gas Reporting Program data and Envirofacts tables, 2011-2023."),
    c("eGRID", "EPA", "Plant-level generation and emissions workbooks."),
    c("DMR",   "EPA", "Discharge Monitoring Report annual pollutant loadings, 2014-2023."))),
  list(group = "Crosswalk", items = list(
    c("FRS Program Links", "EPA / FRS", "Facility Registry Service crosswalk that attaches a shared facility ID."))))

# output cards: title, description, href (or "" when nothing is published), meta
CARDS <- list(
  list(title = "Modular summary tables",
       desc  = "Variable-level summaries of the central table of each of the seven RCRAInfo modules.",
       href  = "summary-tables/modular.html", meta = "7 modules"),
  list(title = "Biennial Report summary tables",
       desc  = "Twelve Biennial Report cycles, 2001 to 2023, summarized variable by variable.",
       href  = "summary-tables/biennial-report.html", meta = "12 cycles"),
  list(title = "State reporting reference",
       desc  = "How each state runs hazardous-waste reporting: system, requirements, and state-specific waste codes.",
       href  = "state-reporting.html", meta = "reference"),
  list(title = "Facility panels",
       desc  = "Balanced and unbalanced LQG / TSDF facility-cycle panels, plus facility-month compliance-evaluation and enforcement panels (2015-2023).",
       href  = paste0(REPO, "/tree/main/code/modules/03_panels"), meta = "4 panels / code"))

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

head_html <- function(title, desc) paste0(
  "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n",
  "<meta charset=\"utf-8\"/>\n",
  "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"/>\n",
  "<title>", esc(title), "</title>\n",
  "<meta name=\"description\" content=\"", esc(desc), "\"/>\n",
  "<link rel=\"icon\" href=\"", FAVICON, "\"/>\n",
  FONT_LINKS,
  "<link rel=\"stylesheet\" href=\"assets/site.css\"/>\n",
  "</head>\n<body>\n")

# masthead + navigation (institutional data-portal chrome; no brand logo mark)
chrome <- function(active) {
  items <- list(
    c("index.html#pipeline",    "Pipeline"),
    c("index.html#data",        "Data"),
    c("index.html#outputs",     "Outputs"),
    c("state-reporting.html",   "State Reporting"))
  links <- vapply(items, function(it) {
    cls <- if (identical(it[2], active)) " class=\"on\"" else ""
    sprintf('<a href="%s"%s>%s</a>', it[1], cls, it[2])
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

# horizontal UVA Batten lockup — official school artwork (resources/batten-logo.png,
# scraped from batten.virginia.edu, copied into docs/assets/ by copy_assets())
BATTEN_LOGO <- paste0(
  '<img class="batten" src="assets/batten-logo.png" width="850" height="147" ',
  'alt="University of Virginia, Frank Batten School of Leadership and Public Policy"/>')

footer_html <- function() paste0(
  '<div class="footlogo"><div class="wrap footlogo-in">',
  BATTEN_LOGO,
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
      '<li><div class="src-h"><span class="src-name">', esc(it[1]),
      '</span><span class="tag">', esc(it[2]), '</span></div>',
      '<p>', esc(it[3]), '</p></li>'), "")
    paste0('<div class="card srccard"><h3>', esc(g$group), '</h3><ul class="src-list">',
           paste(rows, collapse = ""), '</ul></div>')
  }, "")
  paste0(
    '<section class="sec" id="data"><div class="wrap">',
    section_head("Nine public EPA sources",
                 paste0("Downloaded at run time; only the FRS crosswalk is fetched by hand. ",
                        "None are redistributed here.")),
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
  'The raw files are not committed to the repository because of their size; with one manual ',
  'exception they are fully reproducible by running the code, which downloads the current release ',
  'of each dataset. Because EPA refreshes these datasets on rolling schedules, a later run downloads ',
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
    chrome("State reporting"),
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
  dst <- file.path(DOCS, "summary-tables"); dir.create(dst, recursive = TRUE, showWarnings = FALSE)
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
.mnav-in{display:flex;gap:28px;align-items:center;height:52px;overflow-x:auto;}
.mnav a{font-family:var(--sans);font-size:14.5px;color:var(--ink);text-decoration:none;
  white-space:nowrap;padding:16px 0;border-bottom:2px solid transparent;}
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
table.states td{padding:16px;border-bottom:1px solid var(--line);vertical-align:top;color:var(--muted);}
table.states tr:last-child td{border-bottom:0;}
table.states tbody tr:hover td{background:var(--gray-2);}
td.st{color:var(--ink);min-width:190px;}
td.st strong{display:block;font-size:15px;font-weight:600;margin-bottom:3px;color:var(--ink);}
td.st .sys{font-size:12.5px;color:var(--faint);}
td .dot{color:var(--faint);margin:0 3px;}
.note{font-family:var(--sans);font-size:13px;color:var(--faint);margin:20px 0 0;max-width:74ch;}

/* highlighter marks — clean translucent marker sweeping the lower half of the text */
.hl-g,.hl-y{color:inherit;-webkit-box-decoration-break:clone;box-decoration-break:clone;
  padding:.02em .08em;border-radius:.1em;}
.hl-g{background:linear-gradient(120deg,rgba(150,205,140,.5),rgba(150,205,140,.55)) 0 86%/100% 55% no-repeat;}
.hl-y{background:linear-gradient(120deg,rgba(255,213,102,.55),rgba(255,213,102,.6)) 0 86%/100% 55% no-repeat;}
td.st .sys.hl-y{display:inline-block;padding:.08em .34em;border-radius:.14em;margin-top:3px;
  background:linear-gradient(120deg,rgba(255,213,102,.5),rgba(255,213,102,.55));}
.hl-key{font-family:var(--sans);font-size:13px;color:var(--muted);margin:16px 0 0;}
.hl-key .hl-g,.hl-key .hl-y{font-weight:500;color:var(--ink);}

/* footer */
.footlogo{background:var(--card);border-top:1px solid var(--line);}
.footlogo-in{display:flex;align-items:center;justify-content:space-between;gap:20px;
  flex-wrap:wrap;padding:26px 0;}
.batten{height:46px;width:auto;max-width:100%;}
.footlogo-link{font-family:var(--sans);font-size:13.5px;color:var(--navy);}
.footbar{background:var(--bar);color:#c3c8cf;padding:34px 0;}
.footbar p{margin:0 0 10px;font-family:var(--sans);font-size:13.5px;line-height:1.55;max-width:80ch;}
.footbar-meta{color:#8b929c;font-size:12.5px;}
.footbar a{color:#dfe2e7;}
.footbar a:hover{color:#fff;}

@media (max-width:900px){
  .grid-4{grid-template-columns:repeat(2,1fr);}
  .grid-3{grid-template-columns:1fr;}
}
@media (max-width:560px){
  .wrap{padding:0 20px;}
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
if (!length(args) || "index" %in% args) build_index()
if (!length(args) || "state" %in% args) build_state()
if (!length(args))                        copy_summaries()
cat("Site ready under ", DOCS, "/\n", sep = "")
