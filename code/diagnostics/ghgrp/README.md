# ghgrp Download

This inventory is the EPA Greenhouse Gas Reporting Program (GHGRP), reporting
years 2011 through 2023. It is not part of the pipeline; see the
[diagnostics README](../README.md) for how these inventories are meant to be
used.

`01_download_data.R` gathers two kinds of files. It downloads the annual data
summary spreadsheets and a set of subpart workbooks as bulk files from EPA, and it
pulls the subpart emission tables from the Envirofacts REST API in fixed size
chunks. The set of tables and years to pull is driven by
`all_ghgrp_tables_years.csv`, which sits next to the script. Everything is written
under `data/ghgrp/` and kept raw.

The download produces:

| File / folder | What it includes |
|---------------|------------------|
| `data_summaries/GHGRP_SUMMARY_<year>.xlsx` | Annual GHGRP facility summary: direct emitters, suppliers, onshore oil & gas, LDCs, and related sheets. |
| `GHGRP_CEMS.xlsx` | Full data set for subparts E, S-CEMS, BB, CC, LL (adipic acid, lime, silicon carbide, soda ash, coal-based liquid fuel suppliers). |
| `GHGRP_FLUORINATED.xlsx` | Subparts L and O: fluorinated-gas production and destruction, HCFC-22 production / HFC-23 destruction. |
| `tables/<year>/<TABLE>.csv` | Envirofacts subpart emissions tables, pulled from the REST API and kept under their EPA table names (already descriptive, e.g. `EF_W_EMISSIONS_SOURCE_GHG.csv`). |
