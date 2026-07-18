# 01_download

Note: All three folders in this module have been verified.

This stage downloads the raw data the project is built on and scrapes the
matching EPA data dictionaries. Every later stage reads from what this stage
produces under `data/`.

There is one subfolder per data source, and each has its own README with the
details.

- [echo_rcra](echo_rcra/README.md) is the EPA ECHO RCRAInfo extract for hazardous
  waste sites.
- [echo_rcra_pipeline](echo_rcra_pipeline/README.md) is the EPA ECHO RCRA pipeline
  dataset of monitoring activities with linked violations and enforcement.
- [rcrainfo](rcrainfo/README.md) is the complete set of RCRAInfo module tables
  from the Hazardous Waste Information Platform.

Each source has a download script and a dictionary scraping script. The scripts
write into `data/<source>/`, and each data folder carries its own README that
describes the downloaded files. The raw data is not committed to the repository
because of its size, and it is reproduced by running these scripts.

Download scripts for five supplementary EPA inventories (TRI, NEI, GHGRP, eGRID,
DMR) live outside the pipeline in [code/diagnostics](../../diagnostics/README.md);
the master script does not run them.

One input is not downloaded by code. The EPA Facility Registry Service Program
Links file must be downloaded by hand and placed at
`data/frs/FRS_PROGRAM_LINKS.csv`, where the panel stage uses it to attach facility
identifiers. The [root README](../../../README.md) explains where to obtain it.

## Running

The master script runs the whole stage in order. To run a single source on its
own, run its script from the repository root, for example
`Rscript code/modules/01_download/rcrainfo/01_download_data.R`.
