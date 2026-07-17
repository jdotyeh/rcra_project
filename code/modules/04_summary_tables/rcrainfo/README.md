# 04_summary_tables

This module builds one summary workbook for the central table of each RCRAInfo
module and one for each Biennial Report cycle. Each workbook describes its table
variable by variable, with categorical frequencies, quantitative ranges, and yes
or no indicator counts, laid out in a fixed house format.

## Scripts

`00_function.R` is the shared engine. It defines the function that computes the
summaries and writes a workbook in the house format, and it is sourced by every
other script here. Running it on its own only defines functions and produces
nothing.

The numbered scripts are thin configurations. Each one loads a single raw table,
declares which of its columns are categorical, quantitative, or indicators along
with their value labels, and then calls the engine.

| Script | Table summarized | Workbook written |
|--------|------------------|------------------|
| `01_hd_reporting.R` | HD_REPORTING | Handler Module Summary Tables.xlsx |
| `02_ce_reporting.R` | CE_REPORTING | CME Module Summary Tables.xlsx |
| `03_ca_event.R` | CA_EVENT | Corrective Action Module Summary Tables.xlsx |
| `04_pm_reporting.R` | PM_EVENT | Permitting Module Summary Tables.xlsx |
| `05_fa_cost_estimate.R` | FA_COST_ESTIMATE | Financial Assurance Module Summary Tables.xlsx |
| `06_wt_notices_exports.R` | WT_NOTICES_EXPORTS | WIETS Exports Module Summary Tables.xlsx |
| `07_wt_notices_imports.R` | WT_NOTICES_IMPORTS | WIETS Imports Module Summary Tables.xlsx |
| `08_br_reporting_2001.R` through `19_br_reporting_2023.R` | BR_REPORTING_2001 through BR_REPORTING_2023, one cycle each | Biennial Report `<cycle>` Summary Tables.xlsx |

## What it reads and writes

The scripts read the raw module tables under `data/rcrainfo/`, and the Biennial
Report scripts also read the Handler NAICS lookup table for its labels. Every
workbook is written to `output/summary_tables/` with a descriptive name such as
`Handler Module Summary Tables.xlsx`.

The workbooks are compiled into two standalone HTML pages by
`code/utils/summary_tables_to_html.R`, which is a convenience tool outside the
pipeline. See [code/utils/README.md](../../../utils/README.md).

## Running

The master script runs the whole stage. To rebuild one workbook, run its script
from the repository root, for example
`Rscript code/modules/04_summary_tables/rcrainfo/01_hd_reporting.R`. Each script
sources the engine by its repository path, so always run from the root.
