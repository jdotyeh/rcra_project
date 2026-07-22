# FRS Data

The EPA FRS Program Links and Facilities files, downloaded by
`code/modules/01_download/frs/01_download_data.R` from the FRS archive that EPA
publishes through ECHO. The [module README](../../code/modules/01_download/frs/README.md)
describes the download.

| File | What it holds |
|------|---------------|
| `FRS_PROGRAM_LINKS.csv` | A national cross-reference from program-system identifiers to FRS registry identifiers, roughly six hundred megabytes. |
| `FRS_FACILITIES.csv` | One row per FRS facility, roughly four hundred megabytes, carrying the facility's `REGISTRY_ID`, address (`FAC_STREET`, `FAC_CITY`, `FAC_STATE`, `FAC_ZIP`), and geocoded `LATITUDE_MEASURE` / `LONGITUDE_MEASURE`. |

The panel stage reads Program Links to attach a registry identifier to each
handler, matching the RCRAInfo Handler ID against `PGM_SYS_ID` on the rows where
`PGM_SYS_ACRNM` is `RCRAINFO` and carrying `REGISTRY_ID` as the panel's
`FRS_ID`. The Handler master reads Facilities to overwrite a facility's reported
coordinates with the FRS pair for the same registry identifier, joining
`REGISTRY_ID` to that `FRS_ID` and importing `LATITUDE_MEASURE` and
`LONGITUDE_MEASURE` under the record-level rules documented in the
[Handler master module](../../code/modules/02_modular_master_files/rcrainfo/README.md).
The registry identifier is the bridge from the hazardous waste records to the
other environmental datasets in `data/`, and the reasoning and its limits are set
out in the
[facility identifiers brief](../../docs/institutional_briefs/09_facility_identifiers.md).
