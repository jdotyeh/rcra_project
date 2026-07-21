# RCRAInfo Data

The complete set of RCRAInfo module tables from the EPA Hazardous Waste
Information Platform, downloaded by
`code/modules/01_download/rcrainfo/01_download_data.R`. These tables are the
backbone of the summary, master-file, and panel stages. There is one lower-case
folder per module.

| Folder | Module | What it covers |
|--------|--------|----------------|
| `hd/` | Handler | Who a site is and what it does, its central record plus many dimension tables. |
| `br/` | Biennial Report | The periodic waste reports filed by larger sites, one table per cycle. |
| `ce/` | Compliance Monitoring and Enforcement | Evaluations, violations, and enforcement actions. |
| `ca/` | Corrective Action | Cleanup of releases at regulated facilities. |
| `pm/` | Permitting | Permits, closure, and post-closure events. |
| `fa/` | Financial Assurance | Cost estimates and the mechanisms that fund them. |
| `wt/` | Waste Import Export Tracking System | Cross-border movement of hazardous waste. |
| `em/` | e-Manifest | Shipment tracking. |

Each module folder also holds a scraped `<MODULE>_DATA_DICTIONARY.md` that
describes its columns, written by `02_scrape_data_dictionary.R`, and EPA's
`METADATA.txt` with record counts. The Handler folder is the largest, with the
central table and dozens of dimension tables.

For what each module means as a piece of the program, start with the
[institutional overview](../../docs/institutional_briefs/00_overview.md), which maps every
module to the brief that explains it.
