# 04_summary_tables

This module builds one summary workbook for the master file of each RCRAInfo
module and one for each Biennial Report cycle. Each workbook describes its
source variable by variable, with categorical frequencies, quantitative ranges,
and binary indicator counts, laid out in a fixed house format.

## Scripts

`00_function.R` is the shared engine. It defines the function that computes the
summaries and writes a workbook in the house format, and it is sourced by every
other script here. Running it on its own only defines functions and produces
nothing. The Dummy tab counts indicators in either coding, the 1/0 of the
master files or the Y/N of the raw Biennial Report tables, and carries a pair
of Unknown columns for the "U" code some master flags hold (the recode rules
live in the [master-file stage README](../../02_modular_master_files/rcrainfo/README.md)).

The numbered scripts are thin configurations. The module scripts (01-07) each
load one master file from `output/modular_master_files/`, so every summary
describes the analysis-ready file the panels are built from rather than a raw
central table; the Biennial Report scripts (08-19) load one raw cycle file
each. Every script declares which of its columns are categorical, quantitative,
or indicators along with their value labels, and then calls the engine.

| Script | File summarized | Workbook written |
|--------|-----------------|------------------|
| `01_hd_reporting.R` | HD_MASTER | Handler Module Summary Tables.xlsx |
| `02_ce_reporting.R` | CE_MASTER | CME Module Summary Tables.xlsx |
| `03_ca_event.R` | CA_MASTER | Corrective Action Module Summary Tables.xlsx |
| `04_pm_reporting.R` | PM_MASTER | Permitting Module Summary Tables.xlsx |
| `05_fa_cost_estimate.R` | FA_MASTER | Financial Assurance Module Summary Tables.xlsx |
| `06_wt_notices_exports.R` | WT_EXPORTS_MASTER | WIETS Exports Module Summary Tables.xlsx |
| `07_wt_notices_imports.R` | WT_IMPORTS_MASTER | WIETS Imports Module Summary Tables.xlsx |
| `08_br_reporting_2001.R` through `19_br_reporting_2023.R` | BR_REPORTING_2001 through BR_REPORTING_2023, one cycle each | Biennial Report `<cycle>` Summary Tables.xlsx |

Each workbook's overview band states the master's unit of analysis (its
banner), so a reader sees what one row is before reading any variable.

## Which variables are covered

The seven module workbooks summarize every column of their master file that
carries a coded, dated, numeric, or indicator value. A column is left out only
when it holds a record identifier, a personal name or staff identifier, a
correspondence address or contact detail, free-text notes, or the description
text that labels a code already summarized in the same workbook. The overview
band counts the columns left out and the note block under the Categorical table
names each of them, so a reader can see the whole file accounted for.

Two consequences of that rule are worth stating. First, the site's own
geography stays in even though it is part of an address, because the region,
state, county, ZIP, tribal land, and coordinates are what place a record on the
map, while the mailing, contact, owner, and operator address blocks are left
out. Second, sequence numbers are summarized on the Quantitative tab rather
than dropped as identifiers, because their spread shows how many owners, areas,
units, violations, or mechanisms a record carries.

## What it reads and writes

The module scripts read the master files under `output/modular_master_files/`,
so the master-file stage must run first; the master script runs the stages in
that order. The Financial Assurance script also reads the FA lookup tables
under `data/rcrainfo/fa/` for its value labels, and the Biennial Report scripts
read the raw cycle tables under `data/rcrainfo/br/` plus the Handler NAICS
lookup table for labels. Every workbook is written to `output/summary_tables/`
with a descriptive name such as `Handler Module Summary Tables.xlsx`.

The workbooks are compiled into two standalone HTML pages by
`code/utils/summary_tables_to_html.R`, which is a convenience tool outside the
pipeline. See [code/utils/README.md](../../../utils/README.md).

## Running

The master script runs the whole stage. To rebuild one workbook, run its script
from the repository root, for example
`Rscript code/modules/04_summary_tables/rcrainfo/01_hd_reporting.R`. Each script
sources the engine by its repository path, so always run from the root.
