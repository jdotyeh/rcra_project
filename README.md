# Resource Conservation and Recovery Act (RCRA) Regulatory Data Infrastructure

## Overview

The code in this package builds a facility-level research infrastructure around hazardous waste regulation under the Resource Conservation and Recovery Act (RCRA). It has four stages, run in order by one master script:

1. **Download** (`01_download`): downloads and documents hazardous waste compliance and enforcement data from two EPA platforms — ECHO (Enforcement and Compliance History Online) and RCRAInfo (via the Hazardous Waste Information Platform, HWIP) — plus the EPA FRS Program Links file that the panel stage links facilities through. Each RCRA source also scrapes the corresponding EPA data dictionary.
2. **Modular master files** (`02_modular_master_files`): one analysis-ready master CSV per RCRAInfo module (Handler, CME, Corrective Action, Permitting, Financial Assurance, WIETS exports/imports), joining each module's central table with its dimension tables.
3. **Panels** (`03_panels`): facility panels built from the master files and the Biennial Report — a balanced and an unbalanced facility-cycle panel of LQG/TSDF facilities (2015–2023), a facility-month compliance-evaluation panel (2015–2023), and a facility-month enforcement-action panel (2015–2023) — each linked to EPA FRS IDs.
4. **Summary tables** (`04_summary_tables`): variable-level summary workbooks for the master file of each RCRAInfo module and each Biennial Report cycle.

The replicator should expect the download stage to run for roughly 1–2 hours on a fast connection, the processing stages (2–4) to add roughly 1–2 hours, and the package to use about 45 GB of disk space.

Download scripts for five supplementary EPA facility-level inventories — the Toxics Release Inventory (TRI), the National Emissions Inventory (NEI), the Greenhouse Gas Reporting Program (GHGRP), the Emissions & Generation Resource Integrated Database (eGRID), and Discharge Monitoring Report (DMR) loadings — are kept outside the pipeline in `code/diagnostics/` as useful data inventories for extracting more information about the panel facilities; the master script does not run them (see `code/diagnostics/README.md`).

## Data Availability and Provenance Statements

All data used in this project are public U.S. federal government data published by the EPA. The raw data files are not committed to this repository because of their size (about 40 GB); they are fully reproducible by running the code, which downloads the current release of each dataset.

Note that EPA refreshes these datasets on a rolling basis (ECHO weekly, HWIP exports weekly with dated snapshot paths), so a later run will download a newer vintage than the one described below. The RCRA data used here were exported by EPA on 2026-07-05 and downloaded on 2026-07-06; the FRS file was downloaded on 2026-07-09.

### Statement about Rights

- [x] I certify that the author(s) of the manuscript have legitimate access to and permission to use the data used in this manuscript.
- [x] I certify that the author(s) of the manuscript have documented permission to redistribute/publish the data contained within this replication package.

### License for Data

The data are works of the U.S. federal government (EPA) and are in the public domain.

### Summary of Availability

- [x] All data **are** publicly available.

### Details on each Data Source

#### 1. ECHO RCRA Pipeline Dataset (EPA, 2026a)

All Compliance Monitoring Activities (CMA) with linked violations and enforcement actions. Downloaded as `pipeline_rcra_downloads.zip` (~40 MB) from https://echo.epa.gov/files/echodownloads/pipeline_rcra_downloads.zip (listed at https://echo.epa.gov/tools/data-downloads). Format: CSV. The data dictionary is scraped from https://echo.epa.gov/tools/data-downloads/rcra-pipeline-download-summary and saved as `PIPELINE_DATA_DICTIONARY.md`; the bundled READ ME table is converted to `PIPELINE_READ_ME.md`.

Data folder: `data/echo_rcra_pipeline/`

#### 2. ECHO RCRAInfo Dataset (EPA, 2026b)

RCRA compliance and enforcement extract for hazardous waste sites (facilities, evaluations, violations, violation/SNC history, enforcements, NAICS). Downloaded as `rcra_downloads.zip` (~113 MB) from https://echo.epa.gov/files/echodownloads/rcra_downloads.zip (listed at https://echo.epa.gov/tools/data-downloads). Format: CSV. The data dictionary and the RCRAInfo description are scraped from https://echo.epa.gov/tools/data-downloads/rcrainfo-download-summary and saved as `RCRA_DATA_DICTIONARY.md` and `RCRA_READ_ME.md`.

Data folder: `data/echo_rcra/`

#### 3. RCRAInfo CSV Exports, Hazardous Waste Information Platform (EPA, 2026c)

Complete RCRAInfo module tables: Biennial Report (br), Corrective Action (ca), Compliance Monitoring and Enforcement (ce), e-Manifest (em), Financial Assurance (fa), Handler (hd), Permitting (pm), and WIETS (wt). Zip files are listed at https://rcrapublic.epa.gov/rcra-hwip/data-access/csv-downloads and served through the HWIP API (`https://rcrapublic.epa.gov/rcra-hwip/api/export/{summaries,modules,tables}`), which points to dated Amazon S3 snapshots; the code queries the API at run time to get the current links. About 4.3 GB zipped and 38 GB unzipped. Format: CSV. Tables with more than one million records ship as numbered part files; the code appends them into one CSV per table.

The data dictionaries are scraped from the RCRAInfo Public Data Element Dictionary help site (https://rcrainfo.epa.gov/rcrainfo-help/application/publicHelp/index.htm) and saved per module as `data/rcrainfo/<module>/<MODULE>_DATA_DICTIONARY.md`.

Data folder: `data/rcrainfo/<module>/` (one lower-case folder per module)

#### 4. FRS Program Links (EPA, 2026e)

EPA FRS national Program Links file (`FRS_PROGRAM_LINKS.csv`, ~600 MB), which cross-references program-system IDs (including RCRAInfo Handler IDs) to FRS `REGISTRY_ID`s. Downloaded as `frs_downloads.zip` (~1 GB, of which only the Program Links CSV is kept) from https://echo.epa.gov/files/echodownloads/frs_downloads.zip (documented at https://echo.epa.gov/tools/data-downloads/frs-download-summary; the same file is described on the FRS data resources page, https://www.epa.gov/frs/frs-data-resources). Format: CSV. Used by the panel stage to attach `FRS_ID`.

Data folder: `data/frs/`

## Dataset list

| Data file(s) | Source | Notes | Provided |
|---|---|---|---|
| `data/echo_rcra_pipeline/PIPELINE_*.csv` | EPA (2026a) | 4 tables + `PIPELINE_READ_ME.md`, `PIPELINE_DATA_DICTIONARY.md` | No (downloaded by code) |
| `data/echo_rcra/RCRA_*.csv` | EPA (2026b) | 6 tables + `RCRA_READ_ME.md`, `RCRA_DATA_DICTIONARY.md` | No (downloaded by code) |
| `data/rcrainfo/br/*` | EPA (2026c) | Biennial Report tables incl. `BR_REPORTING_2001`-`2023` | No (downloaded by code) |
| `data/rcrainfo/ca/*` | EPA (2026c) | Corrective Action tables | No (downloaded by code) |
| `data/rcrainfo/ce/*` | EPA (2026c) | Compliance Monitoring & Enforcement tables incl. `CE_REPORTING` | No (downloaded by code) |
| `data/rcrainfo/em/*` | EPA (2026c) | e-Manifest tables incl. `EM_MANIFEST` | No (downloaded by code) |
| `data/rcrainfo/fa/*` | EPA (2026c) | Financial Assurance tables | No (downloaded by code) |
| `data/rcrainfo/hd/*` | EPA (2026c) | Handler tables incl. `HD_REPORTING` | No (downloaded by code) |
| `data/rcrainfo/pm/*` | EPA (2026c) | Permitting tables | No (downloaded by code) |
| `data/rcrainfo/wt/*` | EPA (2026c) | WIETS tables incl. `WT_AR_2022`-`2024` | No (downloaded by code) |
| `data/frs/FRS_PROGRAM_LINKS.csv` | EPA (2026e) | FRS program-ID cross-reference | No (downloaded by code) |
| `output/modular_master_files/<MOD>_MASTER.csv` | derived | 7 RCRAInfo module master files (~4 GB) | No (rebuilt by code) |
| `output/panels/BR_PANEL_*`, `output/panels/summary/*` | derived | BR balanced/unbalanced facility-cycle panels and panel summaries | Yes (small, committed) |
| `output/panels/CE_PANEL_2015_2023/*` | derived | Facility-month evaluation and enforcement panels | No (large, rebuilt by code) |
| `output/summary_tables/*.xlsx` | derived | 19 module/BR-cycle summary workbooks (compiled to `*.html` by `code/utils/summary_tables_to_html.R`) | Yes (committed) |

Each `data/rcrainfo/<module>/` folder also contains EPA's `METADATA.txt` (record counts) and a scraped `<MODULE>_DATA_DICTIONARY.md`. The supplementary inventories downloadable by `code/diagnostics/` (TRI, NEI, GHGRP, eGRID, DMR) are not part of this package's dataset list; each is documented in its `code/diagnostics/<inventory>/README.md`.

## Computational requirements

### Software Requirements

- R 4.4.2
  - `rvest` (1.0.5)
  - `xml2` (1.4.0)
  - `jsonlite` (2.0.0)
  - `tidyverse` (2.0.0)
  - `lubridate` (1.9.4)
  - `openxlsx2` (1.25)
- An internet connection is required: all data are downloaded at run time.

### Controlled Randomness

- [x] No Pseudo random generator is used in the analysis described here.

### Memory, Runtime, Storage Requirements

#### Summary time to reproduce

Approximate time needed to reproduce the analyses on a standard (2026) desktop machine:

- [x] 2-4 hours for one full pass: downloads are dominated by the RCRA archives (~4.5 GB zipped, ~38 GB unzipped); the master-file stage adds roughly an hour (HD_HANDLER alone is 2.2 GB) and the summary-table and panel stages a few minutes each.

#### Summary of required storage space

Approximate storage space needed:

- [x] 25 GB - 250 GB (about 45 GB: ~40 GB raw data + ~5 GB derived outputs)

Memory requirements: the download and summary stages stream to disk and are light; the master-file and panel stages load large tables and are most comfortable with 16 GB+ of RAM.

#### Computational Details

The code was last run on an **Apple M3 Pro laptop (18 GB RAM) with macOS 26.5.2**: RCRA downloads on 2026-07-06 and the master-file and panel stages on 2026-07-09.

## Description of programs/code

- `code/master.R` runs every module script in order. It discovers all `.R` files under `code/modules/` and sources them in alphabetical path order, each in its own environment, so `00_setup` (install and load packages, create the output folders) runs first and stages `01_download` through `04_summary_tables` follow. It skips the `build_panels.R` shortcut described below so the panels are not built twice.
- Programs in `code/modules/01_download/` (`echo_rcra/`, `echo_rcra_pipeline/`, `rcrainfo/`, `frs/`) download the raw data and scrape the data dictionaries: `01_download_data.R` downloads the zip file(s), unzips into the source's `data/` folder, deletes the zips, and (where applicable) renames files and appends numbered part files into one CSV per table; `02_scrape_data_dictionary.R` (the three RCRA sources) scrapes the EPA documentation page(s) and writes markdown data dictionaries (and READ ME files) next to the data. The `frs/` module keeps only `FRS_PROGRAM_LINKS.csv` from its archive.
- Programs in `code/diagnostics/` (`tri/`, `nei/`, `ghgrp/`, `egrid/`, `dmr/`) — supplementary data inventories outside the pipeline, one `01_download_data.R` each, porting the download step of EPA's StEWI package (`standardizedinventories`) to R against the current EPA endpoints. Helper inputs are vendored next to the scripts (`dmr/state_codes.csv`, `ghgrp/all_ghgrp_tables_years.csv`). Each writes a raw, unparsed copy of its inventory into `data/<inventory>/`; `master.R` never runs them (see `code/diagnostics/README.md`).
- Programs in `code/modules/02_modular_master_files/rcrainfo/` (`01_hd_master.R` - `07_wt_imports_master.R`) build one master CSV per RCRAInfo module under `output/modular_master_files/`: the module's central table joined with its dimension tables (one row per source record x dimension combination, all columns read as character so identifiers and date stamps survive verbatim).
- Programs in `code/modules/03_panels/rcrainfo/` build the facility panels under `output/panels/` (all link `FRS_ID` from the FRS Program Links file):
  - `01_panel_2015_2023_balanced.R` — balanced facility-cycle panel (`BR_PANEL_2015_2023_BALANCED.csv`) of handlers recognized in the Biennial Report as LQG and/or TSDF in **all five** cycles 2015-2023; Biennial Report status/tonnage columns plus duration-dominant handler attributes and a same-year conflict audit column from `HD_MASTER`.
  - `01_panel_2015_2023_balanced_summary.R` — descriptive summaries of the balanced panel (numeric and categorical), written to `output/panels/summary/` as CSVs and a two-sheet workbook.
  - `02_panel_2015_2023_unbalanced.R` — unbalanced counterpart of the balanced panel (`BR_PANEL_2015_2023_UNBALANCED.csv`): every handler recognized as LQG and/or TSDF in **at least one** cycle, one row per qualifying cycle; a strict superset built by the same rules.
  - `03_panel_eval_2015_2023.R` — balanced facility-month panel (`EVAL_PANEL_2015_2023.csv`) of RCRA compliance evaluations from `CE_MASTER`, months 2015-01 - 2023-12, with per-month evaluation counts by type, violation indicators, the responsible person and state-prefixed suborganization codes (e.g. `IL-CD`), citizen-complaint, multimedia, sampling, and not-Subtitle-C attribute indicators, and the latest evaluation change stamp.
  - `04_panel_enf_2015_2023.R` — balanced facility-month panel (`ENF_PANEL_2015_2023.csv`) of RCRA enforcement actions from `CE_MASTER`, months 2015-01 - 2023-12, with per-month action counts split by issuing agency (state vs federal), the nationally-defined and undefined enforcement-type codes, and the docket, attorney, responsible-person, state-prefixed suborganization (e.g. `IL-CD`), disposition, and CA/FO fields.
  - `build_panels.R` — shortcut that builds only the panels end to end: setup, the FRS Program Links download and the RCRAInfo download if the raw inputs are missing, the `HD_MASTER` and `CE_MASTER` master files if they are missing, then the four panels. Excluded from `master.R` so a full run does not build the panels twice.
- Programs in `code/modules/04_summary_tables/rcrainfo/` build one "`<Module>` Summary Tables.xlsx" workbook per RCRAInfo module (variable-level summaries of the module's master file: categorical frequencies, quantitative ranges, and 1/0 indicators with their unknown counts) under `output/summary_tables/`:
  - `00_function.R` — the shared engine (`build_module_summary()`); sourced by the other scripts, it computes the summaries and writes the workbook in a fixed house format. Running it on its own only defines functions.
  - `01_hd_reporting.R` - `07_wt_notices_imports.R` — one config per module master: Handler (`HD_MASTER`), CME (`CE_MASTER`), Corrective Action (`CA_MASTER`), Permitting (`PM_MASTER`), Financial Assurance (`FA_MASTER`), and WIETS exports/imports (`WT_*_MASTER`). Each config covers every column of its master that carries a coded, dated, numeric, or indicator value; record identifiers, personal names and staff identifiers, correspondence addresses and contact details, free-text notes, and the description text paired with a summarized code are left out and named in the workbook.
  - `08_br_reporting_2001.R` - `19_br_reporting_2023.R` — one config per Biennial Report cycle (`BR_REPORTING_2001`-`2023`), summarizing the raw cycle files.
- `code/utils/summary_tables_to_html.R` — convenience utility (not part of the pipeline): compiles the summary-table workbooks into two standalone HTML files under `output/summary_tables/` (`Modular Summary Tables.html` and `Biennial Report Summary Tables.html`), each with a linked table of contents; see `code/utils/README.md`.
- `code/utils/build_site.R` — convenience utility (not part of the pipeline): assembles a minimalist public-facing website under `docs/` from artifacts already in the repository — a project overview, a searchable state-by-state RCRA reporting reference (rendered from `resources/table.md`), and the two compiled summary-table pages — designed to be served by GitHub Pages from the `/docs` folder while remaining openable by double-clicking `docs/index.html`; see `code/utils/README.md`.
- `docs/institutional_briefs/` — institutional briefs on the hazardous waste program, an overview plus one brief per topic, written so the program rules behind the data are documented in one place. Where a rule shapes the data, the relevant module or data README points to the brief.
- `resources/` — reference documents (not used by the code): EPA RCRA notification/reporting forms (`epa_forms/`) and RCRAInfo module structure charts (`rcrainfo_modular_structure_charts/`).
- Output folders are created automatically; raw data folders are excluded from version control via `.gitignore`, while summary workbooks and the BR panels in `output/` are committed.
- Every code module and most data and output folders carry their own README, so a reader can start from any folder and understand what it holds and how it is built.

### License for Code

The code is licensed under the terms in `LICENSE`.

## Instructions to Replicators

1. Install R (4.4.2 or later) and the packages listed above, e.g. `install.packages(c("rvest", "xml2", "jsonlite", "tidyverse", "lubridate", "openxlsx2"))`.
2. From the repository root, run:

   ```sh
   Rscript code/master.R
   ```

3. All datasets and data dictionaries appear under `data/`; summary workbooks under `output/summary_tables/`; module master files under `output/modular_master_files/`; panels under `output/panels/`. Individual module scripts can also be run on their own (from the repository root), e.g. `Rscript code/modules/01_download/rcrainfo/01_download_data.R`. To build only the panels without running the whole pipeline, run `Rscript code/modules/03_panels/rcrainfo/build_panels.R`, which runs setup, the FRS and RCRAInfo downloads if their raw inputs are missing, the required master files, and then the panels.

Note: because EPA refreshes these data on rolling schedules, downloaded files will reflect the current release, not necessarily the vintage documented above.

## References

- U.S. EPA (2026a). "RCRA Pipeline Dataset." Enforcement and Compliance History Online (ECHO). https://echo.epa.gov/tools/data-downloads (accessed 2026-07-06).
- U.S. EPA (2026b). "RCRAInfo Dataset." Enforcement and Compliance History Online (ECHO). https://echo.epa.gov/tools/data-downloads (accessed 2026-07-06).
- U.S. EPA (2026c). "RCRAInfo CSV Downloads." Hazardous Waste Information Platform (HWIP). https://rcrapublic.epa.gov/rcra-hwip/data-access/csv-downloads (accessed 2026-07-06).
- U.S. EPA (2026d). "RCRAInfo Public Data Element Dictionary." https://rcrainfo.epa.gov/rcrainfo-help/application/publicHelp/index.htm (accessed 2026-07-06).
- U.S. EPA (2026e). "FRS Data Resources." https://www.epa.gov/frs/frs-data-resources (accessed 2026-07-09).
- U.S. EPA. "StEWI: Standardized Emission and Waste Inventories." https://github.com/USEPA/standardizedinventories (download logic reference for the `code/diagnostics/` inventory scripts).

## Acknowledgements

This README follows the template of the Social Science Data Editors (https://social-science-data-editors.github.io/template_README/). The supplementary inventory scripts in `code/diagnostics/` port the download step of EPA's open-source StEWI package (USEPA/standardizedinventories) to R.
