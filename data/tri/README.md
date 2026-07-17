# TRI Data

EPA Toxics Release Inventory (TRI) Basic Plus files, downloaded by
`code/modules/01_download/tri/01_download_data.R`. One folder per reporting year
(the year is in the folder path, not the file name). Files are tab-delimited and
kept raw as downloaded.

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
