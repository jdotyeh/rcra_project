# egrid Download

This inventory is the EPA Emissions and Generation Resource Integrated Database
(eGRID), plant level workbooks for data years 2014, 2016, and 2018 through 2023.
It is not part of the pipeline; see the [diagnostics README](../README.md) for
how these inventories are meant to be used.

`01_download_data.R` downloads one workbook per year into `data/egrid/` and keeps
each one raw with no sheet parsing. Most years are a single direct download, while
the 2014 and 2016 workbooks are distributed only inside EPA's historical archive,
so the script downloads that archive once and extracts the two workbooks from it.

The download produces:

| File | What it includes |
|------|------------------|
| `EGRID_PLANT_<year>.xlsx` | Annual eGRID data workbook. Plant-level emissions and generation, plus sheets for units, generators, states, balancing authorities, and a US summary. |
