# ghgrp Download

This source is the EPA Greenhouse Gas Reporting Program, reporting years 2011
through 2023.

`01_download_data.R` gathers two kinds of files. It downloads the annual data
summary spreadsheets and a set of subpart workbooks as bulk files from EPA, and it
pulls the subpart emission tables from the Envirofacts REST API in fixed size
chunks. The set of tables and years to pull is driven by
`all_ghgrp_tables_years.csv`, which sits next to the script. Everything is written
under `data/ghgrp/`.

The downloaded files are documented in
[data/ghgrp/README.md](../../../../data/ghgrp/README.md).
