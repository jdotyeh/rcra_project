# nei Download

This source is the EPA National Emissions Inventory point source data, reporting
years 2011 through 2022.

`01_download_data.R` downloads EPA staged Apache Parquet extracts from the EPA ORD
Data Commons storage bucket, the same extracts EPA's own inventory tooling reads,
and keeps them raw with no parsing. The files are written under `data/nei/`, one
folder per year, and each year holds the EPA region groupings.

The downloaded files are documented in
[data/nei/README.md](../../../../data/nei/README.md).
