# FRS Data

The EPA Facility Registry Service Program Links file. This is the one input the
project does not download by code, because it must be obtained by hand from the
Facility Registry Service data resources page and placed here as
`FRS_PROGRAM_LINKS.csv`. The [root README](../../README.md) gives the source and
the download step.

| File | What it holds |
|------|---------------|
| `FRS_PROGRAM_LINKS.csv` | A national cross-reference from program-system identifiers to Facility Registry Service registry identifiers, roughly six hundred megabytes. |

The panel stage reads this file to attach a registry identifier to each handler,
matching on the program-system identifier where the program acronym marks it as a
RCRAInfo record. The registry identifier is the bridge from the hazardous waste
records to the other environmental datasets in `data/`, and the reasoning and its
limits are set out in the
[facility identifiers brief](../../docs/institutional/09_facility_identifiers.md).
