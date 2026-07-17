# =============================================================================
# FILE:     00_function.R
# PURPOSE:  Shared engine behind every RCRAInfo "<Module> Summary Tables.xlsx"
#           workbook. A module script sources this file, defines its column spec,
#           and calls build_module_summary() to write one workbook.
# INPUTS:   none (sourced by the module scripts 01-19 in this folder)
# OUTPUTS:  none of its own; defines build_module_summary(), which writes the
#           workbooks under output/summary_tables/
# AUTHOR:   Jason Ye
# CREATED:  2026-07-07
# UPDATED:  2026-07-07
# =============================================================================

# Shared engine for the RCRAInfo "<Module> Summary Tables.xlsx" workbooks.
# A module script (01_*.R - 19_*.R in this folder) loads its raw table,
# defines a spec (which columns are Categorical / Quantitative / Dummy, plus
# value labels), and calls build_module_summary(); the engine computes the
# summaries and writes a workbook under output/summary_tables/ in the fixed
# house format (three tabs: Categorical, Quantitative, Dummy; a tab is
# omitted if the module has no variables of that type).
#
# House format (do not change): Calibri 12; variable names black, descriptions
# gray (FF666666); overview band green (B5E6A2); categorical header light green
# (D2F3C6); quantitative header blue (A6C9EC); dummy header gold (FFD966); thin
# black grid; merged variable blocks; "%" one decimal; dates yyyy-mm-dd.
#
# The workbooks are compiled into two standalone HTML files (a full table of
# contents, all tables in the house look) by code/utils/summary_tables_to_html.R.
#
# Sourced by the module scripts; running this file on its own only defines
# functions. Requires: tidyverse, lubridate, openxlsx2.

suppressMessages({
  library(tidyverse); library(lubridate); library(openxlsx2)
})

# ---- House palette / font ---------------------------------------------------
.col_band   <- "FFB5E6A2"; .col_cathdr <- "FFD2F3C6"
.col_quant  <- "FFA6C9EC"; .col_dummy  <- "FFFFD966"
.ink_black  <- "FF000000"; .ink_gray   <- "FF666666"
.FONT <- "Calibri"; .SIZE <- 12

# openxlsx2 stores width as (requested + 0.7109375 padding); subtract to match.
cw <- function(w) w - 0.7109375

# ---- Shared helpers ---------------------------------------------------------
# House convention: descriptions derived from lookup / "_DESC" files are shown
# in Title Case (capitalize the first letter of every word).
prettify <- function(s) str_to_title(s)

# value -> "value - label" when a label exists, otherwise the bare value.
apply_labels <- function(values, labels) {
  if (is.null(labels)) return(values)
  hit <- values %in% names(labels)
  values[hit] <- paste0(values[hit], " - ", labels[values[hit]])
  values
}

# percent rounded to 1 dp, dropping a trailing ".0": 0.571->"0.6", 48.0->"48".
pct1 <- function(p) { p <- round(p, 1)
  ifelse(p == round(p), as.character(round(p)), formatC(p, format = "f", digits = 1)) }

# wrap a vector of names into quoted, comma-separated lines that fit the merged
# "Variables Not Summarized" cell (B:F ~= 78 chars wide, no wrap).
wrap_quoted <- function(nm, width = 76) {
  if (!length(nm)) return("(none)")
  items <- paste0("'", nm, "'"); lines <- character(); cur <- ""
  for (i in seq_along(items)) {
    sep <- if (i < length(items)) "," else ""
    add <- if (cur == "") items[i] else paste0(cur, ", ", items[i])
    if (nchar(paste0(add, sep)) > width && cur != "") { lines <- c(lines, paste0(cur, ",")); cur <- items[i] }
    else cur <- add
  }
  if (cur != "") lines <- c(lines, cur)
  paste(lines, collapse = "\n")
}

# Compute the columns a module config must load (spec columns + paired desc cols).
needed_columns <- function(cat_spec, quant_dates = character(), quant_nums = integer(),
                           flag_simple = character(), flag_composite = character(),
                           id_col, extra = character()) {
  desc_cols <- map_chr(cat_spec, function(s)
    if (is.character(s$labels) && length(s$labels) == 1 && str_starts(s$labels, "desc:"))
      str_remove(s$labels, "desc:") else NA_character_)
  unique(c(id_col, map_chr(cat_spec, "col"), na.omit(desc_cols),
           quant_dates, names(quant_nums), flag_simple, names(flag_composite), extra))
}

# =============================================================================
# build_module_summary() — compute summaries and write the workbook
# =============================================================================
build_module_summary <- function(data, all_cols, out_file, id_col, temporal_col,
    banner, cat_spec, quant_dates = character(), quant_nums = integer(),
    flag_simple = character(), flag_composite = character(),
    rcra_start = as.Date("1976-01-01"), today = Sys.Date(), topk = 5L,
    module_desc = NULL, missing_notes = NULL, not_summarized = NULL) {

  n_total <- nrow(data)
  if (is.null(module_desc)) module_desc <- ""

  # columns referenced only as a description source ("desc:<COL>") are used
  # (they label a summarized variable), so they do not count as dropped.
  desc_cols <- map_chr(cat_spec, function(s)
    if (is.character(s$labels) && length(s$labels) == 1 && str_starts(s$labels, "desc:"))
      str_remove(s$labels, "desc:") else NA_character_)
  desc_cols <- as.character(na.omit(desc_cols))

  # resolve any "desc:<COL>" label schemes into named vectors derived from data
  derive_labels <- function(code_col, desc_col) {
    tibble(code = data[[code_col]], d = data[[desc_col]]) |>
      filter(!is.na(code), code != "", !is.na(d), d != "") |>
      count(code, d) |> group_by(code) |> slice_max(n, n = 1, with_ties = FALSE) |>
      ungroup() |> transmute(code, lab = prettify(d)) |> deframe()
  }
  cat_spec <- map(cat_spec, function(s) {
    if (is.character(s$labels) && length(s$labels) == 1 && str_starts(s$labels, "desc:"))
      s$labels <- derive_labels(s$col, str_remove(s$labels, "desc:"))
    if (is.null(s$active)) s$active <- FALSE
    s
  })

  # ---- overview ----
  n_handlers <- n_distinct(data[[id_col]])
  td  <- ymd(data[[temporal_col]], quiet = TRUE)
  tdp <- td[!is.na(td) & td >= rcra_start & td <= today]
  temporal <- sprintf("%s to %s", format(min(tdp)), format(max(tdp)))
  summarized <- c(map_chr(cat_spec, "col"), quant_dates, names(quant_nums),
                  flag_simple, names(flag_composite))
  # columns present in the source file but not summarized (and not used as a
  # description source); listed by name in a note block under the Categorical tab.
  dropped <- setdiff(all_cols, c(summarized, desc_cols, id_col))
  # default: a concise count + broad categories (override via `not_summarized`).
  if (is.null(not_summarized)) {
    not_summarized <- sprintf(
      "%d other columns not summarized (identifiers, names, and descriptions / free-text fields).",
      length(dropped))
  }

  # ---- categorical blocks ----
  build_cat_block <- function(s) {
    x <- data[[s$col]]; x[x == ""] <- NA
    n_miss <- sum(is.na(x)); n_cat <- n_distinct(x, na.rm = TRUE)
    fr    <- tibble(value = x) |> filter(!is.na(value)) |> count(value, sort = TRUE)
    shown  <- slice_head(fr, n = topk)
    n_rest <- n_cat - nrow(shown)
    # if exactly one category would fall into "All Other", name it instead
    if (n_rest == 1) { shown <- slice_head(fr, n = topk + 1L); n_rest <- 0L }
    vals  <- apply_labels(shown$value, s$labels); Ns <- shown$n
    if (n_rest > 0) {
      vals <- c(vals, sprintf("All Other (%d)", n_rest))
      Ns   <- c(Ns, sum(fr$n) - sum(shown$n))
    }
    list(name = s$name, desc = s$desc,
         miss = sprintf("%s%%\n(%d)", pct1(100 * n_miss / n_total), n_miss),
         ncat = n_cat, vals = vals,
         pct = round(100 * Ns / n_total, 1), N = Ns, active = isTRUE(s$active))
  }
  cat_blocks <- map(cat_spec, build_cat_block)

  # ---- quantitative rows ----
  q_date <- function(v) {
    d <- ymd(data[[v]], quiet = TRUE); nm <- sum(is.na(d))
    q <- quantile(d, c(0, .05, .95, 1), na.rm = TRUE, type = 1)
    list(name = v, N = n_total - nm, miss = round(100 * nm / n_total, 1), stats = q, date = TRUE)
  }
  q_num <- function(v, dg) {
    x <- suppressWarnings(as.numeric(data[[v]])); nm <- sum(is.na(x))
    q <- quantile(x, c(0, .05, .95, 1), na.rm = TRUE)
    list(name = v, N = n_total - nm, miss = round(100 * nm / n_total, 1), stats = round(q, dg), date = FALSE)
  }
  quant_rows <- c(map(quant_dates, q_date), imap(quant_nums, ~ q_num(.y, .x)))

  # ---- dummy rows ----
  dummy_stat <- function(yes, no, miss_n) {
    yn <- sum(yes, na.rm = TRUE); nn <- sum(no, na.rm = TRUE)
    c(miss_n, round(100 * miss_n / n_total, 2),
      yn, round(100 * yn / n_total, 2), nn, round(100 * nn / n_total, 2))
  }
  dummy_names <- character(); dummy_vals <- list()
  for (v in flag_simple) {
    x <- data[[v]]; x[x == ""] <- NA
    dummy_names <- c(dummy_names, v)
    dummy_vals  <- c(dummy_vals, list(dummy_stat(x == "Y", x == "N", sum(is.na(x)))))
  }
  for (v in names(flag_composite)) {
    x <- data[[v]]; x[x == ""] <- NA
    act <- str_detect(x, flag_composite[[v]])
    dummy_names <- c(dummy_names, v)
    dummy_vals  <- c(dummy_vals, list(dummy_stat(act, !act, sum(is.na(act)))))
  }

  # ===========================================================================
  # WRITE
  # ===========================================================================
  wb <- wb_workbook()
  add_grid <- function(sheet, dims) wb$add_border(sheet, dims = dims,
                                                  left_border = "thin", right_border = "thin", top_border = "thin", bottom_border = "thin",
                                                  inner_hgrid = "thin", inner_vgrid = "thin",
                                                  left_color = wb_color(hex = .ink_black), right_color = wb_color(hex = .ink_black),
                                                  top_color = wb_color(hex = .ink_black), bottom_color = wb_color(hex = .ink_black),
                                                  inner_hcolor = wb_color(hex = .ink_black), inner_vcolor = wb_color(hex = .ink_black))

  get_missing_notes <- function(tab) {
    if (is.null(missing_notes)) return(character())
    if (is.list(missing_notes)) {
      out <- missing_notes[[tab]]
      if (is.null(out)) character() else out
    } else {
      missing_notes
    }
  }

  # write a titled note block (header + lines) in the house note format; return
  # the next free row (leaving a one-row gap), or start_row if nothing written.
  # All lines go into ONE merged cell spanning the full table width (A:end_col),
  # so every note block looks the same: big bordered cell, Calibri 11, wrapped.
  add_note_block <- function(sheet, start_row, end_col, header, notes) {
    if (!length(notes)) return(start_row)
    note_lines <- c(header, notes)
    end_row <- start_row + length(note_lines) - 1L
    note_rng <- paste0("A", start_row, ":", end_col, end_row)

    wb$add_data(sheet, paste(note_lines, collapse = "\n"),
                dims = paste0("A", start_row), col_names = FALSE)
    wb$merge_cells(sheet, dims = note_rng)

    add_grid(sheet, note_rng)
    wb$add_font(sheet, dims = note_rng,
                name = .FONT, size = 11, color = wb_color(hex = .ink_black))
    wb$add_cell_style(sheet, dims = note_rng,
                      vertical = "top", wrap_text = TRUE)
    end_row + 2L
  }
  add_missing_notes <- function(sheet, start_row, end_col, notes)
    add_note_block(sheet, start_row, end_col, "Notes on missing values:", notes)

  COLS <- LETTERS[1:7]

  # -- Sheet 1: Categorical ---------------------------------------------------
  # overview band rows 1-5, column header row 6, variable blocks from row 7
  wb$add_worksheet("Categorical", grid_lines = TRUE)
  wb$add_data("Categorical", module_desc,                dims = "A1", col_names = FALSE)
  wb$add_data("Categorical", banner,                     dims = "A2", col_names = FALSE)
  wb$add_data("Categorical", "Total Observations",       dims = "A3", col_names = FALSE)
  wb$add_data("Categorical", n_total,                    dims = "B3", col_names = FALSE)
  wb$add_data("Categorical", "Temporal Range",           dims = "C3", col_names = FALSE)
  wb$add_data("Categorical", temporal,                   dims = "D3", col_names = FALSE)
  wb$add_data("Categorical", "Distinct Facilities",      dims = "A4", col_names = FALSE)
  wb$add_data("Categorical", n_handlers,                 dims = "B4", col_names = FALSE)
  wb$add_data("Categorical", "Variables Not Summarized", dims = "A5", col_names = FALSE)
  wb$add_data("Categorical", not_summarized,             dims = "B5", col_names = FALSE)
  hdr6 <- c("Variables", "Missing", "# Categories", "Most Frequent Values", "%", "N")
  for (j in seq_along(hdr6)) wb$add_data("Categorical", hdr6[j], dims = paste0(COLS[j], "6"), col_names = FALSE)

  r <- 7L; cat_merges <- list(); active_F <- character()
  for (b in cat_blocks) {
    k <- length(b$vals); r0 <- r; r1 <- r + k - 1L
    wb$add_data("Categorical",
                fmt_txt(paste0(b$name, "\n"), font = .FONT, size = .SIZE, color = wb_color(hex = .ink_black)) +
                  fmt_txt(b$desc, font = .FONT, size = .SIZE, color = wb_color(hex = .ink_gray)),
                dims = paste0("A", r0), col_names = FALSE)
    wb$add_data("Categorical", b$miss, dims = paste0("B", r0), col_names = FALSE)
    wb$add_data("Categorical", b$ncat, dims = paste0("C", r0), col_names = FALSE)
    wb$add_data("Categorical", b$vals, dims = paste0("D", r0), col_names = FALSE)
    wb$add_data("Categorical", b$pct,  dims = paste0("E", r0), col_names = FALSE)
    wb$add_data("Categorical", b$N,    dims = paste0("F", r0), col_names = FALSE)
    if (k > 1L) cat_merges <- c(cat_merges,
                                list(paste0("A", r0, ":A", r1), paste0("B", r0, ":B", r1), paste0("C", r0, ":C", r1)))
    if (b$active) active_F <- paste0("F", r0, ":F", r1)
    r <- r1 + 1L
  }
  last <- r - 1L; rng_all <- paste0("A1:F", last)
  add_grid("Categorical", rng_all)
  wb$add_font("Categorical", dims = rng_all, name = .FONT, size = .SIZE, color = wb_color(hex = .ink_black))
  wb$add_fill("Categorical", dims = "A1:F5", color = wb_color(hex = .col_band))
  wb$add_fill("Categorical", dims = "A6:F6", color = wb_color(hex = .col_cathdr))
  wb$add_numfmt("Categorical", dims = paste0("E6:E", last), numfmt = "0.0")
  if (length(active_F)) wb$add_numfmt("Categorical", dims = active_F, numfmt = "0.0")
  wb$add_cell_style("Categorical", dims = "A1:F5", vertical = "center", wrap_text = TRUE)
  wb$add_cell_style("Categorical", dims = "A6:F6", vertical = "center")
  wb$add_cell_style("Categorical", dims = paste0("A7:A", last), vertical = "center")
  wb$add_cell_style("Categorical", dims = paste0("B7:C", last), vertical = "center", horizontal = "center")
  wb$add_cell_style("Categorical", dims = paste0("D7:F", last), vertical = "center")
  wb$set_col_widths("Categorical", cols = 1:6,
                    widths = cw(c(28.5, 18.5, 15.83203125, 24.33203125, 8.1640625, 11)))
  for (m in c("A1:F1", "A2:F2", "C3:C4", "D3:F4", "B5:F5", unlist(cat_merges)))
    wb$merge_cells("Categorical", dims = m)

  nr <- add_missing_notes("Categorical", last + 2L, "F", get_missing_notes("categorical"))
  dropped_lines <- if (length(dropped)) strsplit(wrap_quoted(dropped), "\n")[[1]] else character()
  add_note_block("Categorical", nr, "F",
                 "Variables dropped (present in the source file but not summarized):",
                 dropped_lines)

  # -- Sheet 2: Quantitative (only if the module has quantitative variables) --
  if (length(quant_rows)) {
    wb$add_worksheet("Quantitative", grid_lines = TRUE)
    qhdr <- c("Variables", "N", "% Missing", "Min", "P5", "P95", "Max")
    for (j in seq_along(qhdr)) wb$add_data("Quantitative", qhdr[j], dims = paste0(COLS[j], "1"), col_names = FALSE)
    text_date_cells <- character()
    for (i in seq_along(quant_rows)) {
      rr <- i + 1L; q <- quant_rows[[i]]
      wb$add_data("Quantitative", q$name, dims = paste0("A", rr), col_names = FALSE)
      wb$add_data("Quantitative", q$N,    dims = paste0("B", rr), col_names = FALSE)
      wb$add_data("Quantitative", q$miss, dims = paste0("C", rr), col_names = FALSE)
      for (j in 1:4) {
        cell <- paste0(COLS[3 + j], rr); val <- q$stats[[j]]
        if (q$date && !is.na(val) && as.Date(val) < as.Date("1900-01-01")) {
          wb$add_data("Quantitative", format(as.Date(val), "%Y-%m-%d"), dims = cell, col_names = FALSE)
          text_date_cells <- c(text_date_cells, cell)
        } else {
          wb$add_data("Quantitative", val, dims = cell, col_names = FALSE)
        }
      }
    }
    qlast <- length(quant_rows) + 1L; qrng <- paste0("A1:G", qlast)
    add_grid("Quantitative", qrng)
    wb$add_font("Quantitative", dims = qrng, name = .FONT, size = .SIZE, color = wb_color(hex = .ink_black))
    wb$add_fill("Quantitative", dims = "A1:G1", color = wb_color(hex = .col_quant))
    date_rows <- 1L + which(map_lgl(quant_rows, "date"))
    if (length(date_rows)) wb$add_numfmt("Quantitative",
                                         dims = paste0("D", min(date_rows), ":G", max(date_rows)), numfmt = "yyyy-mm-dd")
    wb$add_cell_style("Quantitative", dims = qrng, vertical = "center")
    for (cl in text_date_cells) wb$add_cell_style("Quantitative", dims = cl, vertical = "center", horizontal = "right")
    wb$set_col_widths("Quantitative", cols = 1, widths = cw(23.0))
    wb$set_col_widths("Quantitative", cols = 2:7, widths = cw(12.6640625))
    add_missing_notes("Quantitative", qlast + 2L, "G", get_missing_notes("quantitative"))
  }

  # -- Sheet 3: Dummy (only if the module has binary indicator variables) -----
  if (length(dummy_vals)) {
    wb$add_worksheet("Dummy", grid_lines = TRUE)
    dhdr <- c("Variables", "N Missing", "% Missing", "Yes N", "Yes %", "No N", "No %")
    for (j in seq_along(dhdr)) wb$add_data("Dummy", dhdr[j], dims = paste0(COLS[j], "1"), col_names = FALSE)
    for (i in seq_along(dummy_vals)) {
      rr <- i + 1L
      wb$add_data("Dummy", dummy_names[i], dims = paste0("A", rr), col_names = FALSE)
      v <- dummy_vals[[i]]
      for (j in 1:6) wb$add_data("Dummy", v[j], dims = paste0(COLS[1 + j], rr), col_names = FALSE)
    }
    dlast <- length(dummy_vals) + 1L; drng <- paste0("A1:G", dlast)
    add_grid("Dummy", drng)
    wb$add_font("Dummy", dims = drng, name = .FONT, size = .SIZE, color = wb_color(hex = .ink_black))
    wb$add_fill("Dummy", dims = "A1:G1", color = wb_color(hex = .col_dummy))
    wb$add_cell_style("Dummy", dims = drng, vertical = "center")
    wb$set_col_widths("Dummy", cols = 1, widths = cw(28.5))
    wb$set_col_widths("Dummy", cols = 2:7, widths = cw(12.6640625))
    add_missing_notes("Dummy", dlast + 2L, "G", get_missing_notes("dummy"))
  }

  dir.create(dirname(out_file), recursive = TRUE, showWarnings = FALSE)
  wb_save(wb, out_file, overwrite = TRUE)
  cat(sprintf("Wrote %s  (n_total = %s, distinct %s = %s)\n", out_file,
              format(n_total, big.mark = ","), id_col, format(n_handlers, big.mark = ",")))
  invisible(out_file)
}
