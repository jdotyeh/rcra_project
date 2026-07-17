# GHGRP Data

EPA Greenhouse Gas Reporting Program (GHGRP) data, downloaded by
`code/modules/01_download/ghgrp/01_download_data.R`. Kept raw as downloaded.

| File / folder | What it includes |
|---------------|------------------|
| `data_summaries/GHGRP_SUMMARY_<year>.xlsx` | Annual GHGRP facility summary: direct emitters, suppliers, onshore oil & gas, LDCs, and related sheets. |
| `GHGRP_CEMS.xlsx` | Full data set for subparts E, S-CEMS, BB, CC, LL (adipic acid, lime, silicon carbide, soda ash, coal-based liquid fuel suppliers). |
| `GHGRP_FLUORINATED.xlsx` | Subparts L and O: fluorinated-gas production and destruction, HCFC-22 production / HFC-23 destruction. |
| `tables/<year>/<TABLE>.csv` | Envirofacts subpart emissions tables, pulled from the REST API and kept under their EPA table names (already descriptive, e.g. `EF_W_EMISSIONS_SOURCE_GHG.csv`). |
