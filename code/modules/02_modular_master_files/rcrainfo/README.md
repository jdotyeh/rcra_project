# 02_modular_master_files

This stage turns each RCRAInfo module into a single analysis ready master file.
Each script takes the module's central table and joins it to the module's
dimension tables, so that one wide file carries the whole module.

## Scripts

There is one script per module. Each script reads its module folder under
`data/rcrainfo/`, joins the central table to its dimensions with left joins so
that a record with no match in a dimension still keeps a row, and reads every
column as text so that identifiers and date stamps survive exactly as reported.

| Script | Module | Central table | Writes |
|--------|--------|---------------|--------|
| `01_hd_master.R` | Handler | HD_HANDLER | `HD_MASTER.csv` |
| `02_ce_master.R` | Compliance Monitoring and Enforcement | CE_REPORTING | `CE_MASTER.csv` |
| `03_ca_master.R` | Corrective Action | CA_EVENT | `CA_MASTER.csv` |
| `04_pm_master.R` | Permitting | PM_EVENT | `PM_MASTER.csv` |
| `05_fa_master.R` | Financial Assurance | FA_COST_ESTIMATE | `FA_MASTER.csv` |
| `06_wt_exports_master.R` | WIETS exports | WT_NOTICES_EXPORTS | `WT_EXPORTS_MASTER.csv` |
| `07_wt_imports_master.R` | WIETS imports | WT_NOTICES_IMPORTS | `WT_IMPORTS_MASTER.csv` |

## Outputs

Each script writes one file to `output/modular_master_files/`, named for its
module, for example `HD_MASTER.csv`. These master files are the main input to the
panel stage, and the Handler and Compliance master files in particular feed the
facility panels.

## Running

The master script runs the whole stage. To rebuild one master file, run its
script from the repository root, for example
`Rscript code/modules/02_modular_master_files/rcrainfo/01_hd_master.R`. Some of
these tables are large, so the stage is most comfortable with sixteen gigabytes or
more of memory.
