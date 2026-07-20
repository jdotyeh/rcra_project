# FRS Download

Note: This folder has been verified (Jul 19).

This module downloads the EPA FRS Program Links file, the national
cross-reference from program-system identifiers to FRS registry identifiers. The
panel stage reads it to attach a registry identifier to each RCRAInfo handler,
and the reasoning behind that link is set out in the
[facility identifiers brief](../../../../docs/institutional/09_facility_identifiers.md).

## Scripts

`01_download_data.R` downloads the FRS archive that EPA publishes through ECHO
(`frs_downloads.zip`, about one gigabyte), extracts `FRS_PROGRAM_LINKS.csv` into
`data/frs/`, and deletes the archive. The archive also ships the FRS facility,
SIC code, and NAICS code tables, but only the Program Links file is kept,
because it is the one input the pipeline reads.

There is no dictionary scraping script here. The FRS download summary page on
ECHO (https://echo.epa.gov/tools/data-downloads/frs-download-summary) documents
the file's columns, and the three columns the pipeline uses (`PGM_SYS_ACRNM`,
`PGM_SYS_ID`, `REGISTRY_ID`) are described in the
[data folder README](../../../../data/frs/README.md).

## What it writes

| File | What it holds |
|------|---------------|
| `data/frs/FRS_PROGRAM_LINKS.csv` | One row per program-system record known to FRS, roughly six hundred megabytes, linking each program identifier to its `REGISTRY_ID`. |

## Running

The master script runs this module with the rest of the download stage. To run
it on its own, from the repository root:
`Rscript code/modules/01_download/frs/01_download_data.R`. The panel shortcut
`code/modules/03_panels/rcrainfo/build_panels.R` also runs it automatically when
the file is missing.
