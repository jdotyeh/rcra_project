# Modules

The pipeline itself, one numbered folder per stage. `code/master.R` discovers
every script in here and sources them in path order, so the numbering is the run
order.

| Stage | What it does | README |
|-------|--------------|--------|
| `00_setup/` | Installs and loads packages, creates the output folders. | [00_setup](00_setup/README.md) |
| `01_download/` | Downloads the raw EPA data and scrapes the data dictionaries, one subfolder per source. | [01_download](01_download/README.md) |
| `02_modular_master_files/` | Joins each RCRAInfo module into one analysis-ready master CSV. | [02_modular_master_files](02_modular_master_files/README.md) |
| `03_panels/` | Builds the facility panels from the master files and the Biennial Report. | [03_panels](03_panels/README.md) |
| `04_summary_tables/` | Builds a variable-level summary workbook for each module and Biennial Report cycle. | [04_summary_tables](04_summary_tables/README.md) |

The panel-building chain is stages `01` through `03`; stage `04` is descriptive
and depends only on the downloaded data. To build only the panels, use the
shortcut described in the [03_panels README](03_panels/rcrainfo/README.md).

Stages `02` through `04` currently hold a single `rcrainfo/` subfolder because
every processed module so far comes from RCRAInfo; another data system would get
its own sibling folder. Each `rcrainfo/` folder carries the detailed README for
its stage.
