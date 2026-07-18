# nei Download

This inventory is the EPA National Emissions Inventory (NEI) point source data,
reporting years 2011 through 2022. It is not part of the pipeline; see the
[diagnostics README](../README.md) for how these inventories are meant to be
used.

`01_download_data.R` downloads EPA staged Apache Parquet extracts from the EPA ORD
Data Commons storage bucket, the same extracts EPA's own inventory tooling reads,
and keeps them raw with no parsing. The files are written under `data/nei/`, one
folder per year.

Each year folder contains:

| File | What it includes |
|------|------------------|
| `NEI_POINT_0.parquet`, `NEI_POINT_1.parquet`, … | Point-source emissions (facility/unit-level pollutant emissions). Multiple files per year are EPA region groupings that together make up the national point-source dataset; the index follows that region-group order. |
