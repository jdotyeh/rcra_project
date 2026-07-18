# tri Download

This inventory is the EPA Toxics Release Inventory (TRI) Basic Plus files,
reporting years 2011 through 2024. It is not part of the pipeline; see the
[diagnostics README](../README.md) for how these inventories are meant to be
used.

`01_download_data.R` downloads one national archive per year, unzips it into
`data/tri/`, one folder per reporting year, and renames the extracted files to
content tags. The files are tab delimited and are kept raw, because parsing and
subsetting belong to a later cleaning step. The per year download URLs are pinned
in the script.

Each year folder contains:

| File | What it includes |
|------|------------------|
| `TRI_RELEASES.txt` | On-site chemical releases and other waste-management quantities, by facility and chemical (fugitive air, stack air, water, land). |
| `TRI_REDUCTION.txt` | Source-reduction, recycling, treatment, and energy-recovery quantities. |
| `TRI_PROJECTIONS.txt` | Reported and projected waste quantities for the prior, current, and next two years, by facility and chemical. |
| `TRI_TREATMENT.txt` | Waste-stream treatment methods and treatment efficiency, by facility and chemical. |
| `TRI_TRANSFERS.txt` | Off-site transfers of chemicals to receiving facilities (receiving site name, address, RCRA ID). |
| `TRI_POTW.txt` | Transfers to publicly owned treatment works (POTW name and address). |
| `TRI_PARENT.txt` | Parent-company names and facility registry identifiers (domestic and foreign parents, EPA/FRS IDs). |
| `TRI_FACILITY.txt` | Facility identity, location, mailing address, contact, and SIC codes (Form R records). |
| `TRI_SUBMISSION.txt` | Submission-level facility/chemical records with revision codes and comments (Form A and Form R). |
| `TRI_DEPRECATED.txt` | Legacy Basic Plus file 3b; not produced for reporting years after 2010. |

Names map from EPA's file-type codes: 1a, 1b, 2a, 2b, 3a, 3c, 3b, 4, 5, 6.
