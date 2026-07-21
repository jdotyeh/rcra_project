# echo_rcra Data

The EPA ECHO RCRAInfo extract, a compliance and enforcement view of hazardous
waste sites, downloaded by
`code/modules/01_download/echo_rcra/01_download_data.R`. The files are kept raw as
downloaded.

| File | What it holds |
|------|---------------|
| `RCRA_FACILITIES.csv` | One row per hazardous waste site, with identity, location, and program-status fields. |
| `RCRA_EVALUATIONS.csv` | Compliance evaluations, mostly inspections, by site and date. |
| `RCRA_VIOLATIONS.csv` | Violations cited at a site, with the requirement broken and the found and resolved dates. |
| `RCRA_VIOSNC_HISTORY.csv` | History of violation and significant-noncomplier status over time. |
| `RCRA_ENFORCEMENTS.csv` | Enforcement actions taken against a site. |
| `RCRA_NAICS.csv` | Industry codes linked to each site. |

Two documentation files accompany the data. `RCRA_DATA_DICTIONARY.md` describes
the columns, and `RCRA_READ_ME.md` is EPA's own note about the extract, both
written by `02_scrape_data_dictionary.R`.

The program terms behind these tables, including what an evaluation, a violation,
significant noncompliance, and an enforcement action mean, are covered in the
[compliance and enforcement brief](../../docs/institutional_briefs/03_compliance_and_enforcement.md).
