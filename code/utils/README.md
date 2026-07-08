# Utilities

Helper scripts that support the project but are **not** part of the replication
pipeline.

## `br_summary_to_gdoc.R` — paste Biennial Report summary tables into the Google Doc

Rebuilds the tables from `output/summary_tables/Biennial Report <year> Summary
Tables.xlsx` (all three tabs: Categorical, Quantitative, Dummy) as rich HTML in
the workbook's house format (fills, merged variable blocks, gray descriptions,
borders, alignment, note blocks) and puts the result on the macOS clipboard.
Pasting into Google Docs then produces real, formatted Docs tables.

Target: **2026 RCRA Project** doc → *Biennial Report Module* → *BR Summary
Tables* tab. Years are separated by Heading-3 year lines (Georgia 14 bold).

### How to run

Run in Terminal (or the RStudio *Terminal* pane — not the R console), from the
repo root.

**Several years in one paste** (`--with-headers` inserts the Heading-3 year
line before each year's tables — use when the year headers don't exist in the
Doc yet):

```sh
cd ~/GitHub/rcra_project
Rscript code/utils/br_summary_to_gdoc.R --with-headers 2023 2021 2019 2017 2015 2013 2011 2009 2007 2005 2003 2001
```

Then, in the Doc: press **Cmd+Down** to jump to the end of the tab and press
**Cmd+V** once.

**One year, under an existing year header** (tables only):

```sh
Rscript code/utils/br_summary_to_gdoc.R 2023
```

Then click the blank line under that year's header and press **Cmd+V**.

From the R console instead:

```r
setwd("~/GitHub/rcra_project")
system('Rscript code/utils/br_summary_to_gdoc.R --with-headers 2023 2021')
```

### Notes and gotchas

- macOS only: the clipboard is set through `osascript` (`«class HTML»` flavor).
- Requires `openxlsx2`; the workbooks must already exist in
  `output/summary_tables/` (built by `code/modules/02_summary_tables/`).
- Before pasting, make sure the cursor sits on a plain paragraph (toolbar shows
  "Normal text"). Pasting while the cursor is inside a table cell nests the
  whole year inside that table — if that happens, Cmd+Z and paste again from a
  plain paragraph. Cmd+Down (end of tab) is the safest landing spot.
- Dates are kept on one line (`white-space:nowrap`, 100 px date columns);
  the `%` column keeps one decimal, matching the workbook's `0.0` format.
