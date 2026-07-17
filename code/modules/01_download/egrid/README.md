# egrid Download

This source is the EPA Emissions and Generation Resource Integrated Database,
plant level workbooks for data years 2014, 2016, and 2018 through 2023.

`01_download_data.R` downloads one workbook per year into `data/egrid/` and keeps
each one raw with no sheet parsing. Most years are a single direct download, while
the 2014 and 2016 workbooks are distributed only inside EPA's historical archive,
so the script downloads that archive once and extracts the two workbooks from it.

The downloaded files are documented in
[data/egrid/README.md](../../../../data/egrid/README.md).
