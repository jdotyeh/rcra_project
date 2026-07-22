# FRS Download

Note: This folder has been verified (Jul 19).

This module downloads two national files from the EPA FRS archive. The Program
Links file is the cross-reference from program-system identifiers to FRS registry
identifiers, and the panel stage reads it to attach a registry identifier to each
RCRAInfo handler. The Facilities file carries each registry identifier's address
and geocoded coordinates, and the Handler master reads it to overwrite the
coordinates a facility reported with the ones FRS publishes for the same place.
The reasoning behind the link is set out in the
[facility identifiers brief](../../../../docs/institutional_briefs/09_facility_identifiers.md).

## Scripts

`01_download_data.R` downloads the FRS archive that EPA publishes through ECHO
(`frs_downloads.zip`, about one gigabyte), extracts `FRS_PROGRAM_LINKS.csv` and
`FRS_FACILITIES.csv` into `data/frs/`, and deletes the archive. The archive also
ships the SIC and NAICS code tables, but only these two files are kept, because
they are the inputs the pipeline reads.

There is no dictionary scraping script here. The FRS download summary page on
ECHO (https://echo.epa.gov/tools/data-downloads/frs-download-summary) documents
the files' columns. The three Program Links columns the pipeline uses
(`PGM_SYS_ACRNM`, `PGM_SYS_ID`, `REGISTRY_ID`) and the Facilities columns the
coordinate override reads (`REGISTRY_ID`, `FAC_STREET`, `FAC_CITY`, `FAC_STATE`,
`FAC_ZIP`, `LATITUDE_MEASURE`, `LONGITUDE_MEASURE`) are described in the
[data folder README](../../../../data/frs/README.md).

## What it writes

| File | What it holds |
|------|---------------|
| `data/frs/FRS_PROGRAM_LINKS.csv` | One row per program-system record known to FRS, roughly six hundred megabytes, linking each program identifier to its `REGISTRY_ID`. |
| `data/frs/FRS_FACILITIES.csv` | One row per FRS facility, roughly four hundred megabytes, carrying the facility's `REGISTRY_ID`, address, and geocoded `LATITUDE_MEASURE` / `LONGITUDE_MEASURE`. |

## Running

The master script runs this module with the rest of the download stage. To run
it on its own, from the repository root:
`Rscript code/modules/01_download/frs/01_download_data.R`. The panel shortcut
`code/modules/03_panels/rcrainfo/build_panels.R` also runs it automatically when
the file is missing.
