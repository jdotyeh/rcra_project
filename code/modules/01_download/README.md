# 01_download

This stage downloads the raw data the project is built on and, for the RCRA
sources, scrapes the matching EPA data dictionaries. Every later stage reads from
what this stage produces under `data/`.

There is one subfolder per data source, and each has its own README with the
details.

- [echo_rcra](echo_rcra/README.md) is the EPA ECHO RCRAInfo extract for hazardous
  waste sites.
- [echo_rcra_pipeline](echo_rcra_pipeline/README.md) is the EPA ECHO RCRA pipeline
  dataset of monitoring activities with linked violations and enforcement.
- [rcrainfo](rcrainfo/README.md) is the complete set of RCRAInfo module tables
  from the Hazardous Waste Information Platform.
- [tri](tri/README.md), [nei](nei/README.md), [ghgrp](ghgrp/README.md),
  [egrid](egrid/README.md), and [dmr](dmr/README.md) are five supplementary EPA
  facility level environmental datasets.

Each RCRA source has a download script and a dictionary scraping script, while
each supplementary source has a single download script. The scripts write into
`data/<source>/`, and most data folders carry their own README that describes the
downloaded files. The raw data is not committed to the repository because of its
size, and it is reproduced by running these scripts.

One input is not downloaded by code. The EPA Facility Registry Service Program
Links file must be downloaded by hand and placed at
`data/frs/FRS_PROGRAM_LINKS.csv`, where the panel stage uses it to attach facility
identifiers. The [root README](../../../README.md) explains where to obtain it.

## Running

The master script runs the whole stage in order. To run a single source on its
own, run its script from the repository root, for example
`Rscript code/modules/01_download/rcrainfo/01_download_data.R`.
