# tri Download

This source is the EPA Toxics Release Inventory Basic Plus files, reporting years
2011 through 2024.

`01_download_data.R` downloads one national archive per year, unzips it into
`data/tri/`, and renames the extracted files to content tags such as
`TRI_RELEASES` and `TRI_TRANSFERS`. The files are tab delimited and are kept raw,
because parsing and subsetting belong to a later cleaning step. The per year
download URLs are pinned in the script.

The downloaded files are documented in
[data/tri/README.md](../../../../data/tri/README.md).
