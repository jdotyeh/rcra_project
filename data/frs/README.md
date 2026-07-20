# FRS Data

The EPA FRS Program Links file, downloaded by
`code/modules/01_download/frs/01_download_data.R` from the FRS archive that EPA
publishes through ECHO. The [module README](../../code/modules/01_download/frs/README.md)
describes the download.

| File | What it holds |
|------|---------------|
| `FRS_PROGRAM_LINKS.csv` | A national cross-reference from program-system identifiers to FRS registry identifiers, roughly six hundred megabytes. |

The panel stage reads this file to attach a registry identifier to each handler,
matching the RCRAInfo Handler ID against `PGM_SYS_ID` on the rows where
`PGM_SYS_ACRNM` is `RCRAINFO` and carrying `REGISTRY_ID` as the panel's
`FRS_ID`. The registry identifier is the bridge from the hazardous waste
records to the other environmental datasets in `data/`, and the reasoning and its
limits are set out in the
[facility identifiers brief](../../docs/institutional/09_facility_identifiers.md).
