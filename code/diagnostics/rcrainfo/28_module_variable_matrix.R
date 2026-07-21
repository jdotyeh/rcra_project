# =============================================================================
# FILE:     28_module_variable_matrix.R
# PURPOSE:  Module variable matrix — build a wide table of every RCRAInfo module column (across HD, CE, CA, PM, FA, WT, BR) and which of them appear in the panels.
# INPUTS:   data/rcrainfo/**/*.csv, output/panels/**/*.csv
# OUTPUTS:  console prints (and any figure files noted inline below)
# AUTHOR:   Jason Ye
# CREATED:  2026-07
# UPDATED:  2026-07
# =============================================================================

# Build variable-presence matrices per RCRAInfo module, two orientations.
#   vertical   = variables as rows, organized into a multi-level conceptual
#                tree (Excel outline grouping), files as columns.
#   horizontal = files as rows, variables as columns (ordered by the tree).
# Cell "X" = the file contains that variable. Lookup tables (*_LU_*) excluded.
# Handler: the split HSM/Episodic sub-tables are dropped in favor of the merged
# HD_HSM / HD_EPISODIC built by 06/07 (read from output/diagnostics if present).
# Counts first (n_files/n_vars = first count column; the totals line is the
# first/top data row). File names UPPERCASE; variable names Title Case.
# Hierarchy via outline grouping + indent + group border rules (minimal color).
# Calibri font.
# Outputs: output/diagnostics/<module>_matrix_{vertical,horizontal}.{xlsx,csv}
suppressMessages({
  library(data.table)
  library(openxlsx2)
})

ACR <- c("ID","EPA","GIS","HSM","NAICS","NAIC","LQG","VSQG","TSDF","TSD","SNC",
  "BR","PCB","NCAPS","FA","EC","IC","GPRA","SLAB","LQHUW","CA","HQ","US","UIC",
  "K","P","SC","CME","UOM","MOD","UW")
prettify <- function(x) vapply(strsplit(x, " "), function(words) {
  paste(vapply(words, function(t) {
    if (toupper(t) %in% ACR || grepl("[0-9]", t)) toupper(t)
    else paste0(toupper(substr(t, 1, 1)), tolower(substr(t, 2, nchar(t))))
  }, character(1)), collapse = " ")
}, character(1))

# ---- tree node constructors ------------------------------------------------
hdr <- function(name, ...) list(h = name, k = list(...))         # header w/ kids
lf  <- function(rx, b = FALSE, l = NA) list(m = rx, b = b, l = l) # leaf (regex)

# ---- HANDLER taxonomy (user-defined structure) -----------------------------
handler_tree <- list(
  hdr("BASIC INFORMATION",
    hdr("Big Four",
      lf("^HANDLER ID$"), lf("^ACTIVITY LOCATION$"), lf("^SOURCE TYPE$"),
      lf("^SEQ NUMBER$"), lf("^CURRENT RECORD$")),
    hdr("Linkage sequence numbers",
      lf("^OWNER OPERATOR SEQ$"), lf("^NAICS SEQ$"), lf("^HSM SEQ NUMBER$"),
      lf("^CONSOLIDATION SEQ NUMBER$"), lf("^WASTE SEQ NUMBER$")),
    hdr("EPA bookkeeping",
      lf("^HANDLER NAME$"), lf("^RECEIVE DATE$"), lf("^ACKNOWLEDGE FLAG$"),
      lf("^ACKNOWLEDGE DATE$"), lf("^DATE BECAME CURRENT$"),
      lf("^DATE ENDED CURRENT$"))),

  hdr("GEOGRAPHICS & DEMOGRAPHICS",
    lf("^ACCESSIBILITY$"),
    lf("^(LOCATION |COUNTY CODE$|TRIBAL ID$|REGION$|STATE$|LAND TYPE$)",
       b = TRUE, l = "Primary site location"),
    lf("^STATE DISTRICT", b = TRUE, l = "State district")),

  hdr("CONTACT INFORMATION",
    lf("^MAIL ", b = TRUE, l = "Mailing address"),
    lf("^CONTACT (FIRST NAME|MIDDLE INITIAL|LAST NAME|TITLE|EMAIL|NAME)",
       b = TRUE, l = "Contact person"),
    lf("^CONTACT ", b = TRUE, l = "Contact address"),
    lf("^(PHONE$|PHONE EXT$|EMAIL$|FAX$|CITY$|ZIP$|COUNTRY$|STREET NO$|STREET1$|STREET2$)",
       b = TRUE, l = "Other contact fields")),

  hdr("OWNER INFORMATION",
    lf("^OWNER NAME$"), lf("^OWNER TYPE$"), lf("^OWNER SEQ$"),
    lf("^OWNER OPERATOR", b = TRUE, l = "Owner/operator record")),

  hdr("OPERATOR INFORMATION",
    lf("^OPERATOR NAME$"), lf("^OPERATOR TYPE$"), lf("^OPERATOR SEQ$")),

  hdr("FACILITY GENERAL INFORMATION",
    lf("^(NAICS|NAIC[0-9])", b = TRUE, l = "NAICS code"),
    hdr("RCRA-regulated status",
      lf("^NON NOTIFIER$"), lf("^INCLUDE IN NATIONAL REPORT$"),
      lf("^REPORT CYCLE$"), lf("^BR EXEMPT$")),
    lf("^(IN A UNIVERSE$|IN HANDLER UNIVERSES$)", b = TRUE,
       l = "Handler universe flags"),
    hdr("GENERATOR",
      lf("^FED WASTE GENERATOR",   b = TRUE, l = "Federal status"),
      lf("^STATE WASTE GENERATOR", b = TRUE, l = "State status"),
      lf("^SHORT TERM GENERATOR$"),
      lf("^MIXED WASTE GENERATOR$"),
      lf("^(IMPORTER ACTIVITY$|IMPORTER$)", b = TRUE, l = "Importer"),
      lf("^SUBPART K", b = TRUE, l = "Subpart K — academic"),
      lf("^SUBPART P", b = TRUE, l = "Subpart P — pharmaceutical"),
      lf("^RECOGNIZED TRADER", b = TRUE, l = "Subpart H — intl shipment"),
      lf("^SLAB ", b = TRUE, l = "Subpart G — SLAB intl shipment")),
    hdr("TRANSPORTER",
      lf("^TRANSPORTER$"), lf("^TRANSFER FACILITY$")),
    hdr("TSDF — treat / store / dispose",
      lf("^TSD ACTIVITY$"),
      lf("^RECYCLER", b = TRUE, l = "Recycler"),
      lf("^ONSITE BURNER", b = TRUE, l = "On-site burner exempt"),
      lf("^FURNACE EXEMPTION$"),
      lf("^UNDERGROUND INJECTION", b = TRUE, l = "Underground injection"),
      lf("^OFF SITE RECEIPT$"),
      lf("^LQHUW$"),
      lf("^UNIVERSAL WASTE DEST FACILITY$"),
      lf("^(TSD DATE$|TSD TYPE$|COMMERCIAL TSD$|OPERATING TSDF$|AS CONVERTER TSDF$|AS FEDERALLY REGULATED TSDF$|AS STATE REGULATED TSDF$|AS STATE REGULATED HANDLER$|MANIFEST BROKER$)",
         b = TRUE, l = "Other TSD status")),
    lf("^USED OIL", b = TRUE, l = "Cross sub-universe — Used Oil")),

  hdr("ADDITIONAL CONTACT",
    lf("^ADDL CONTACT", b = TRUE, l = "Additional contact")),
  hdr("CERTIFICATION",
    lf("^CERT ", b = TRUE, l = "Certifier")),
  hdr("PERMIT CONTACT (PART A)",
    lf("^PCONTACT", b = TRUE, l = "Permit contact")),
  hdr("OTHER PERMITS",
    lf("^OTHER PERMIT", b = TRUE, l = "Other permit")),
  hdr("STATE-REGULATED ACTIVITY",
    lf("^STATE ACTIVITY", b = TRUE, l = "State activity")),
  hdr("WASTE CODES",
    lf("^(WASTE CODE$|WASTE CODE OWNER$)", b = TRUE, l = "Waste code")),
  hdr("UNIVERSAL WASTE",
    lf("^(UNIVERSAL WASTE|UNIVWASTE|FEDERAL UNIVERSAL WASTE)", b = TRUE,
       l = "Universal waste")),
  hdr("HAZARDOUS SECONDARY MATERIAL",
    lf("^(HSM|REASON FOR NOTIFICATION|FACILITY CODE|LAND BASED UNIT|ACCUMULATED|GENERATED|ACTUAL SHORT TONS|ESTIMATE SHORT TONS)",
       b = TRUE, l = "HSM")),
  hdr("EPISODIC EVENTS",
    lf("^(EPISODIC|PROJECT CODE|OTHER PROJECT DESC|ESTIMATED QUANTITY|START DATE|END DATE|WASTE DESCRIPTION)",
       b = TRUE, l = "Episodic")),
  hdr("LQG CLOSURE & CONSOLIDATION",
    lf("^(CLOSURE TYPE|EXPECTED CLOSURE DATE|NEW CLOSURE DATE|DATE CLOSED|CONSOLIDATION|VSQG)",
       b = TRUE, l = "Closure & consolidation")),
  hdr("CORRECTIVE ACTION & ENFORCEMENT",
    lf("^(SNC|ADDRESSED SNC|UNADDRESSED SNC|IN COMPLIANCE|FULL ENFORCEMENT|EC INDICATOR|IC INDICATOR|CA725 INDICATOR|CA750 INDICATOR|CAWRKLD|CLOSWRKLD|PCWRKLD|PERMWRKLD|PERMIT RENEWAL WRKLD|PERMPROG|GPRA|SUBJCA|NCAPS|FEDERAL INDICATOR|FA REQUIRED|GENSTATUS|ACTIVE SITE|HHANDLER LAST CHANGE)",
       b = TRUE, l = "CA / enforcement / workload")),
  hdr("OTHER ID",
    lf("^(OTHER ID$|SAME FACILITY$|RELATIONSHIP)", b = TRUE, l = "Other ID")),
  hdr("MISC.",
    lf("^PUBLIC NOTES$", b = TRUE, l = "Notes"))
)

permit_tree <- list(
  hdr("KEYS", lf("^HANDLER ID$")),
  hdr("PERMIT SERIES",
    lf("^(SERIES |EVENT SERIES SEQ$|MOD SERIES SEQ$|STANDARDIZED PERMIT IND$)",
       b = TRUE, l = "Series")),
  hdr("PERMIT EVENT",
    lf("^(EVENT |RESPONSIBLE PERSON|SUBORGANIZATION|ACTUAL DATE$|BEST DATE$|EFFECTIVE DATE$|SCHEDULE DATE)",
       b = TRUE, l = "Event")),
  hdr("MODIFICATION EVENT", lf("^MOD ", b = TRUE, l = "Modification")),
  hdr("UNIT",
    lf("^(UNIT SEQ$|UNIT NAME$|NUMBER OF UNITS$|COMMERCIAL STATUS$|LEGAL OPERATING STATUS|CAPACITY)",
       b = TRUE, l = "Unit")),
  hdr("UNIT DETAIL",
    lf("^(UNIT DETAIL|CURRENT UNIT DETAIL$|PROCESS CODE|UOM)", b = TRUE,
       l = "Unit detail")),
  hdr("WASTE", lf("^(WASTE CODE$|WASTE CODE OWNER$)", b = TRUE, l = "Waste"))
)

# ---- walk the tree: assign vars (freq-ordered pool), emit ordered rows ------
walk_tree <- function(tree, var_pool) {
  pool <- var_pool                                  # consumed as matched
  rows <- list(); vtop <- character(0); vtopname <- character(0)
  cur_top <- NA
  take <- function(rx) { hit <- pool[grepl(rx, pool)]
                         pool <<- setdiff(pool, hit); hit }
  emit_var <- function(level, v) {
    rows[[length(rows) + 1]] <<- list(type = "var", level = level,
                                     label = prettify(v), var = v)
    vtop[[v]] <<- cur_top
  }
  emit_hdr <- function(level, name)
    rows[[length(rows) + 1]] <<- list(type = "header", level = level,
                                     label = name, var = NA)
  walk <- function(node, depth) {
    if (!is.null(node$h)) {
      if (depth == 0) cur_top <<- node$h
      emit_hdr(depth, node$h)
      for (ch in node$k) walk(ch, depth + 1)
    } else {
      hit <- take(node$m)
      if (isTRUE(node$b)) {
        if (length(hit)) { emit_hdr(depth, node$l)
          for (v in hit) emit_var(depth + 1, v) }
      } else for (v in hit) emit_var(depth, v)
    }
  }
  for (g in tree) walk(g, 0)
  leftover <- pool
  if (length(leftover)) {
    cur_top <- "UNCLASSIFIED"; emit_hdr(0, "UNCLASSIFIED")
    for (v in leftover) emit_var(1, v)
  }
  list(rows = rows, vtop = vtop)
}

# ---- common styling + write ------------------------------------------------
INDENT <- function(level) strrep("    ", level)

styler <- function(out, stem, axis, rows_meta = NULL, col_group = NULL) {
  nAll <- nrow(out); nc <- ncol(out)
  rHead <- 1L; rTop <- 2L; lastRow <- nAll + 1L; colsData <- 3:nc
  med <- "medium"; gline <- wb_color(hex = "FF7F7F7F")

  wb <- wb_workbook()
  wb$set_base_font(font_name = "Calibri", font_size = 11)
  wb$add_worksheet(stem, grid_lines = FALSE)
  wb$add_data(x = out, na.strings = "")

  wb$add_font(dims = wb_dims(rows = rHead, cols = 1:nc), bold = TRUE)
  wb$add_cell_style(dims = wb_dims(rows = rHead, cols = colsData),
                    text_rotation = 90, vertical = "bottom",
                    horizontal = "center")
  wb$set_row_heights(rows = rHead, heights = 170)
  wb$add_cell_style(dims = wb_dims(rows = 2:lastRow, cols = colsData),
                    horizontal = "center")
  # totals row on top
  wb$add_font(dims = wb_dims(rows = rTop, cols = 1:nc), bold = TRUE,
              italic = TRUE)
  wb$add_fill(dims = wb_dims(rows = rTop, cols = 1:nc),
              color = wb_color(hex = "FFF2F2F2"))
  wb$add_border(dims = wb_dims(rows = rTop, cols = 1:nc), bottom_border = med,
                bottom_color = gline, top_border = NULL, left_border = NULL,
                right_border = NULL)

  if (!is.null(rows_meta)) {
    off <- rTop
    types <- vapply(rows_meta, function(r) r$type, "")
    lvls  <- vapply(rows_meta, function(r) as.integer(r$level), 1L)
    grp0  <- off + which(types == "header" & lvls == 0L)   # top-level headers
    sub1  <- off + which(types == "header" & lvls == 1L)
    deep  <- off + which(types == "header" & lvls >= 2L)
    if (length(grp0)) {
      wb$add_font(dims = wb_dims(rows = grp0, cols = 1:nc), bold = TRUE)
      wb$add_fill(dims = wb_dims(rows = grp0, cols = 1:nc),
                  color = wb_color(hex = "FFD9D9D9"))
    }
    if (length(sub1))
      wb$add_font(dims = wb_dims(rows = sub1, cols = 1), bold = TRUE,
                  italic = TRUE)
    if (length(deep))
      wb$add_font(dims = wb_dims(rows = deep, cols = 1), bold = TRUE)
    # group separators: top border on each group, bottom border closing it
    bounds <- sort(grp0)
    for (i in seq_along(bounds)) {
      wb$add_border(dims = wb_dims(rows = bounds[i], cols = 1:nc),
                    top_border = med, top_color = gline, bottom_border = NULL,
                    left_border = NULL, right_border = NULL)
      bot <- if (i < length(bounds)) bounds[i + 1] - 1L else lastRow
      wb$add_border(dims = wb_dims(rows = bot, cols = 1:nc),
                    bottom_border = med, bottom_color = gline,
                    top_border = NULL, left_border = NULL, right_border = NULL)
    }
    # multi-level outline grouping (detail rows = level >= 1)
    didx <- which(lvls >= 1L)
    try(wb$group_rows(rows = off + didx, levels = lvls[didx],
                      collapsed = FALSE), silent = TRUE)
  }

  if (!is.null(col_group)) {                          # horizontal: column outline
    runs <- rle(as.character(col_group)); pos <- 3L
    for (k in seq_along(runs$lengths)) {
      cols <- pos:(pos + runs$lengths[k] - 1L)
      try(wb$group_cols(cols = cols, collapsed = FALSE), silent = TRUE)
      if (k > 1)
        wb$add_border(dims = wb_dims(rows = 1:lastRow, cols = pos),
                      left_border = med, left_color = gline, top_border = NULL,
                      bottom_border = NULL, right_border = NULL)
      pos <- pos + runs$lengths[k]
    }
  }

  wb$set_col_widths(cols = 1, widths = if (axis == "VARIABLE") 42 else 26)
  wb$set_col_widths(cols = 2, widths = 9)
  wb$set_col_widths(cols = colsData, widths = if (axis == "VARIABLE") 4 else 3.4)
  wb$freeze_pane(first_active_row = 3, first_active_col = 3)
  wb_save(wb, sprintf("output/diagnostics/%s.xlsx", stem))
  fwrite(out, sprintf("output/diagnostics/%s.csv", stem), quote = FALSE)
}

save_vertical <- function(rows, mv, file_order, n_vars, stem) {
  labels <- vapply(rows, function(r) paste0(INDENT(r$level), r$label), "")
  nfil <- vapply(rows, function(r) if (r$type == "var")
                   as.character(sum(mv[r$var, ] == "X")) else "", "")
  data <- matrix("", nrow = length(rows), ncol = length(file_order),
                 dimnames = list(NULL, file_order))
  for (i in which(vapply(rows, function(r) r$type == "var", TRUE)))
    data[i, ] <- mv[rows[[i]]$var, ]
  body <- data.frame(variable = labels, n_files = nfil,
                     as.data.frame(data, stringsAsFactors = FALSE),
                     check.names = FALSE, stringsAsFactors = FALSE)
  top <- c(list(variable = "n_vars (per file)", n_files = as.character(sum(n_vars))),
           as.list(as.character(n_vars)))
  topdf <- as.data.frame(top, check.names = FALSE, stringsAsFactors = FALSE)
  colnames(topdf) <- colnames(body)
  styler(rbind(topdf, body), stem, axis = "VARIABLE", rows_meta = rows)
}

save_horizontal <- function(var_sorted, var_group, mat, file_order, n_vars,
                            file_counts, stem) {
  mh <- mat[, var_sorted, drop = FALSE]; colnames(mh) <- prettify(var_sorted)
  out <- data.frame(file = file_order, n_vars = as.character(n_vars),
                    as.data.frame(mh, stringsAsFactors = FALSE),
                    check.names = FALSE, stringsAsFactors = FALSE)
  top <- c(list(file = "n_files (per variable)",
                n_vars = as.character(sum(file_counts))),
           as.list(as.character(file_counts[var_sorted])))
  topdf <- as.data.frame(top, check.names = FALSE, stringsAsFactors = FALSE)
  colnames(topdf) <- colnames(out)
  styler(rbind(topdf, out), stem, axis = "FILE",
         col_group = var_group[var_sorted])
}

# ---- driver ----------------------------------------------------------------
build_module <- function(dir, module, file_order_pref, tree, drop_files = NULL,
                         extra_files = NULL) {
  paths <- list.files(dir, pattern = "\\.csv$", full.names = TRUE)
  extra <- extra_files[file.exists(extra_files)]
  if (length(extra_files) && length(extra) < length(extra_files))
    cat("   (extra files not found, skipped:",
        paste(setdiff(extra_files, extra), collapse = ", "), ")\n")
  paths <- c(paths, extra)
  paths <- paths[!grepl("_LU_", basename(paths))]
  tbls  <- sub("\\.csv$", "", basename(paths))
  keep  <- !tbls %in% drop_files                    # drop merged-away sub-tables
  paths <- paths[keep]; tbls <- tbls[keep]
  vars_by_file <- setNames(lapply(paths, function(p)
    names(fread(p, nrows = 0))), tbls)
  file_order <- c(file_order_pref[file_order_pref %in% tbls],
                  sort(setdiff(tbls, file_order_pref)))

  allv <- unlist(vars_by_file, use.names = FALSE)
  freq <- sort(table(allv), decreasing = TRUE)
  var_order <- names(freq)[order(-as.integer(freq), names(freq))]

  mat <- t(sapply(file_order, function(tb)
    ifelse(var_order %in% vars_by_file[[tb]], "X", "")))
  rownames(mat) <- file_order; colnames(mat) <- var_order
  n_vars <- rowSums(mat == "X"); file_counts <- colSums(mat == "X")

  w <- walk_tree(tree, var_order)
  rows <- w$rows
  var_sorted <- vapply(Filter(function(r) r$type == "var", rows),
                       function(r) r$var, "")
  var_group <- setNames(unlist(w$vtop[var_sorted]), var_sorted)
  mv <- t(mat); rownames(mv) <- colnames(mat)

  dir.create("output/diagnostics", showWarnings = FALSE, recursive = TRUE)
  save_vertical(rows, mv, file_order, n_vars,
                sprintf("%s_matrix_vertical", module))
  save_horizontal(var_sorted, var_group, mat, file_order, n_vars, file_counts,
                  sprintf("%s_matrix_horizontal", module))
  unclassified <- setdiff(var_order, var_sorted)
  cat(sprintf("[%s] files: %d  variables: %d  unclassified: %d\n", module,
              length(file_order), length(var_order), length(unclassified)))
  if (length(unclassified)) cat("   -> ", paste(unclassified, collapse = ", "),
                                "\n")
}

handler_pref <- c("HD_REPORTING","HD_HANDLER","HD_BASIC","HD_OTHER_ID",
  "HD_OWNER_OPERATOR","HD_NAICS","HD_OTHER_PERMIT","HD_WASTE_CODE",
  "HD_UNIVERSAL_WASTE","HD_CERTIFICATION","HD_STATE_ACTIVITY","HD_ADDL_CONTACT",
  "HD_HSM","HD_LQG_CLOSURE","HD_LQG_CONSOLIDATION","HD_EPISODIC","HD_PART_A")
handler_drop <- c("HD_HSM_BASIC","HD_HSM_ACTIVITY","HD_HSM_WASTE_CODE",
  "HD_HSM_RECYCLER","HD_EPISODIC_EVENT","HD_EPISODIC_PROJECT",
  "HD_EPISODIC_WASTE","HD_EPISODIC_WASTE_CODE")
permit_pref <- c("PM_SERIES","PM_EVENT","PM_MOD_EVENT","PM_EVENT_UNIT_DETAIL",
  "PM_UNIT","PM_UNIT_DETAIL","PM_UNIT_DETAIL_WASTE")

# Merged HD_HSM / HD_EPISODIC come from 06/07 (run those first for full coverage).
build_module("data/rcrainfo/hd", "handler", handler_pref, handler_tree,
             handler_drop,
             extra_files = c("output/diagnostics/HD_HSM.csv",
                             "output/diagnostics/HD_EPISODIC.csv"))
build_module("data/rcrainfo/pm", "permitting", permit_pref, permit_tree)
