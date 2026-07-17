# NEI Data

EPA National Emissions Inventory (NEI) point-source data, downloaded by
`code/modules/01_download/nei/01_download_data.R`. One folder per reporting year
(the year is in the folder path, not the file name). Files are Apache Parquet,
kept raw as downloaded.

| File | What it includes |
|------|------------------|
| `NEI_POINT_0.parquet`, `NEI_POINT_1.parquet`, … | Point-source emissions (facility/unit-level pollutant emissions). Multiple files per year are EPA region groupings that together make up the national point-source dataset; the index follows that region-group order. |
