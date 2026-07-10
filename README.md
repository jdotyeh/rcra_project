# Resource Conservation and Recovery Act (RCRA) Regulatory Infrastructure

## Overview

The code in this package builds a facility-level research infrastructure around hazardous waste regulation under the Resource Conservation and Recovery Act (RCRA). It has four stages, run in order by one master script:

1. **Download** (`01_download`): downloads and documents hazardous waste compliance and enforcement data from two EPA platforms — ECHO (Enforcement and Compliance History Online) and RCRAInfo (via the Hazardous Waste Information Platform, HWIP) — plus five supplementary EPA facility-level environmental datasets: the Toxics Release Inventory (TRI), the National Emissions Inventory (NEI), the Greenhouse Gas Reporting Program (GHGRP), the Emissions & Generation Resource Integrated Database (eGRID), and Discharge Monitoring Report (DMR) loadings. Each RCRA module also scrapes the corresponding EPA data dictionary.
2. **Summary tables** (`02_summary_tables`): variable-level summary workbooks for the central table of each RCRAInfo module.
3. **Modular master files** (`03_modular_master_files`): one analysis-ready master CSV per RCRAInfo module (Handler, CME, Corrective Action, Permitting, Financial Assurance, WIETS exports/imports), joining each module's central table with its dimension tables.
4. **Panels** (`04_panels`): facility panels built from the master files and the Biennial Report — a balanced and an unbalanced facility-cycle panel of LQG/TSDF facilities (2015–2023) and a facility-month compliance-evaluation panel (2015–2023) — each linked to EPA Facility Registry Service (FRS) IDs.

The replicator should expect the download stage to run for roughly 2–4 hours on a fast connection (see the DMR note below: that module alone is rate-limited by EPA and completes only over several resumed runs), the processing stages (2–4) to add roughly 1–2 hours, and the package to use about 60 GB of disk space.

## Data Availability and Provenance Statements

All data used in this project are public U.S. federal government data published by the EPA. The raw data files are not committed to this repository because of their size (about 50 GB); with one manual exception (the FRS Program Links file, source 9), they are fully reproducible by running the code, which downloads the current release of each dataset.

Note that EPA refreshes these datasets on a rolling basis (ECHO weekly, HWIP exports weekly with dated snapshot paths, the supplementary datasets on their own cycles), so a later run will download a newer vintage than the one described below. The RCRA data used here were exported by EPA on 2026-07-05 and downloaded on 2026-07-06; the supplementary datasets (sources 4–8) were downloaded on 2026-07-08 and the FRS file on 2026-07-09.

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

#### 4. TRI Basic Plus Data Files (EPA, 2026e)

Toxics Release Inventory national Basic Plus files, reporting years 2011–2024. One national zip per year (`us_<year>.zip`, ~7–65 MB), served under dated folders at `https://www.epa.gov/system/files/other-files/<YYYY-MM>/us_<year>.zip` (links listed on the TRI Basic Plus page; the per-year URLs are pinned in the download script and were verified live on 2026-07-08). Format: tab-delimited text. The extracted file types are renamed to content tags (`TRI_RELEASES`, `TRI_TRANSFERS`, `TRI_FACILITY`, ...).

Data folder: `data/tri/<year>/`

#### 5. NEI Point-Source Data (EPA, 2026f)

National Emissions Inventory point-source emissions, reporting years 2011–2022 (triennial benchmark years plus interim years). Downloaded as EPA-staged Apache Parquet extracts from the EPA ORD Data Commons S3 bucket (`https://dmap-data-commons-ord.s3.amazonaws.com/stewi/NEI Data Files/`), the same extracts EPA's StEWI package reads; per-year file names are pinned in the download script. About 3.6 GB. Format: Parquet, kept raw (no parsing). Files per year are EPA region groupings saved as `NEI_POINT_<i>.parquet`.

Data folder: `data/nei/<year>/`

#### 6. GHGRP Data (EPA, 2026g)

Greenhouse Gas Reporting Program, reporting years 2011–2023. Two source types: (i) bulk files from https://www.epa.gov/system/files/ — the annual data-summary spreadsheets zip (unzipped to `data/ghgrp/data_summaries/`) and the subpart E/S-CEMS/BB/CC/LL and subpart L/O workbooks; (ii) Envirofacts subpart emissions tables from the REST API at https://data.epa.gov/efservice/, fetched in 5,000-row CSV chunks into `data/ghgrp/tables/<year>/<TABLE>.csv`. The per-year table set is driven by `all_ghgrp_tables_years.csv`, vendored next to the download script. Format: XLSX and CSV.

Data folder: `data/ghgrp/`

#### 7. eGRID Data Workbooks (EPA, 2026h)

Emissions & Generation Resource Integrated Database plant-level workbooks for data years 2014, 2016, and 2018–2023 (one `.xlsx` per year, saved as `EGRID_PLANT_<year>.xlsx`). Most years are direct downloads from the eGRID page (https://www.epa.gov/egrid); 2014 and 2016 ship only inside EPA's historical archive zip, which the code downloads once and extracts. About 104 MB. Format: XLSX, kept raw.

Data folder: `data/egrid/`

#### 8. DMR Annual Pollutant Loadings (EPA, 2026i)

Discharge Monitoring Report annual loadings, reporting years 2014–2023, queried per state from the ECHO Loading Tool REST API (`https://echodata.epa.gov/echo/dmr_rest_services.get_custom_data_annual`; there is no bulk file). Per state and year the code saves the annual loads plus nitrogen- and phosphorus-aggregated variants, along with the pollutant parameter list and per-year state totals. Format: CSV, saved as returned.

**Rate limits:** ECHO caps clients at 300 requests/hour and 1,500/day; a full year is ~168 requests, so the complete 10-year pull spans several days. The script paces requests, skips files already downloaded, and exits cleanly when throttled, so re-running it later resumes where it stopped (and the master script simply continues past it).

Data folder: `data/dmr/<year>/`

#### 9. FRS Program Links (EPA, 2026j) — manual download

EPA Facility Registry Service national Program Links file (`FRS_PROGRAM_LINKS.csv`, ~600 MB), which cross-references program-system IDs (including RCRAInfo Handler IDs) to FRS `REGISTRY_ID`s. This is the one input **not** downloaded by code: obtain the national Program Links CSV from the FRS data resources page (https://www.epa.gov/frs/frs-data-resources) and place it at `data/frs/FRS_PROGRAM_LINKS.csv`. Used by the panel stage to attach `FRS_ID`. Downloaded 2026-07-09.

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
| `data/tri/<year>/TRI_*.txt` | EPA (2026e) | Basic Plus files, 2011-2024, renamed by content | No (downloaded by code) |
| `data/nei/<year>/NEI_POINT_*.parquet` | EPA (2026f) | Point-source extracts, 2011-2022 | No (downloaded by code) |
| `data/ghgrp/*` | EPA (2026g) | Summary workbooks, 2 subpart workbooks, Envirofacts tables 2011-2023 | No (downloaded by code) |
| `data/egrid/EGRID_PLANT_<year>.xlsx` | EPA (2026h) | Plant workbooks 2014, 2016, 2018-2023 | No (downloaded by code) |
| `data/dmr/<year>/DMR_*.csv` | EPA (2026i) | Per-state annual loads + N/P variants, 2014-2023 | No (downloaded by code; multi-day, resumable) |
| `data/frs/FRS_PROGRAM_LINKS.csv` | EPA (2026j) | FRS program-ID cross-reference | No (**manual download**, see source 9) |
| `output/modular_master_files/<MOD>_MASTER.csv` | derived | 7 RCRAInfo module master files (~4 GB) | No (rebuilt by code) |
| `output/panels/*.csv`, `output/panels/summary/*` | derived | BR balanced/unbalanced panels, CE panel, panel summaries | Panels are small and versioned with the repo |
| `output/summary_tables/*.xlsx` | derived | 19 module/BR-cycle summary workbooks | Yes (committed) |

Each `data/rcrainfo/<module>/` folder also contains EPA's `METADATA.txt` (record counts) and a scraped `<MODULE>_DATA_DICTIONARY.md`. Each supplementary data folder (`data/tri/`, `data/nei/`, `data/ghgrp/`, `data/egrid/`, `data/dmr/`) contains a `README.md` documenting its files.

## Computational requirements

### Software Requirements

- R 4.4.2
  - `rvest` (1.0.5)
  - `xml2` (1.4.0)
  - `jsonlite` (2.0.0)
  - `tidyverse` (2.0.0)
  - `lubridate` (1.9.4)
  - `openxlsx2` (1.25)
- An internet connection is required: all data (except the manual FRS file) are downloaded at run time.
- Optional: `googledrive` / `googlesheets4`, only if mirroring the summary
  workbooks to Google Sheets (set `RCRA_PUSH_GSHEET=true`; requires a one-time
  interactive Drive login). Skipped by default.

### Controlled Randomness

- [x] No Pseudo random generator is used in the analysis described here.

### Memory, Runtime, Storage Requirements

#### Summary time to reproduce

Approximate time needed to reproduce the analyses on a standard (2026) desktop machine:

- [x] 3-6 hours for one full pass: downloads are dominated by ~12 GB of files (RCRA ~4.5 GB zipped, TRI/NEI/eGRID/GHGRP ~8 GB) plus the chunked GHGRP API tables; the master-file stage adds roughly an hour (HD_HANDLER alone is 2.2 GB) and the summary-table and panel stages a few minutes each.
- The DMR module cannot finish in one pass: ECHO's request caps (300/hour, 1,500/day) mean the full 2014-2023 pull completes only over several resumed runs on consecutive days. It exits cleanly when throttled and skips completed files on re-run, so the rest of the pipeline is unaffected.

#### Summary of required storage space

Approximate storage space needed:

- [x] 25 GB - 250 GB (about 60 GB: ~50 GB raw data + ~5 GB derived outputs)

Memory requirements: the download and summary stages stream to disk and are light; the master-file and panel stages load large tables and are most comfortable with 16 GB+ of RAM.

#### Computational Details

The code was last run on an **Apple M3 Pro laptop (18 GB RAM) with macOS 26.5.2**: RCRA downloads on 2026-07-06, supplementary downloads on 2026-07-08, and the master-file and panel stages on 2026-07-09.

## Description of programs/code

- `code/master.R` runs every module script in order. It discovers all `.R` files under `code/modules/` and sources them in alphabetical path order (stage `01_download` through `04_panels`), each in its own environment.
- Programs in `code/modules/01_download/` download the raw data and, for the RCRA sources, scrape the data dictionaries:
  - `echo_rcra/`, `echo_rcra_pipeline/`, `rcrainfo/` — `01_download_data.R` downloads the zip file(s), unzips into the module's `data/` folder, deletes the zips, and (where applicable) renames files and appends numbered part files into one CSV per table; `02_scrape_data_dictionary.R` scrapes the EPA documentation page(s) and writes markdown data dictionaries (and READ ME files) next to the data.
  - `tri/`, `nei/`, `ghgrp/`, `egrid/`, `dmr/` — one `01_download_data.R` each, porting the download step of EPA's StEWI package (`standardizedinventories`) to R against the current EPA endpoints. Helper inputs are vendored next to the scripts (`dmr/state_codes.csv`, `ghgrp/all_ghgrp_tables_years.csv`). Each writes a raw, unparsed copy of the source files with standardized names; the DMR script self-throttles and resumes (see source 8).
- Programs in `code/modules/02_summary_tables/rcrainfo/` build one "`<Module>` Summary Tables.xlsx" workbook per RCRAInfo module (variable-level summaries of the central table: categorical frequencies, quantitative ranges, and Y/N indicators) under `output/summary_tables/`:
  - `00_engine.R` — the shared engine (`build_module_summary()`); sourced by the other scripts, it computes the summaries and writes the workbook in a fixed house format. Running it on its own only defines functions.
  - `01_hd_reporting.R` - `07_wt_notices_imports.R` — one config per module: Handler (`HD_REPORTING`), CME (`CE_REPORTING`), Corrective Action (`CA_EVENT`), Permitting (`PM_EVENT`), Financial Assurance (`FA_COST_ESTIMATE`), and WIETS exports/imports (`WT_NOTICES_*`).
  - `08_br_reporting_2001.R` - `19_br_reporting_2023.R` — one config per Biennial Report cycle (`BR_REPORTING_2001`-`2023`).
- Programs in `code/modules/03_modular_master_files/rcrainfo/` (`01_hd_master.R` - `07_wt_imports_master.R`) build one master CSV per RCRAInfo module under `output/modular_master_files/`: the module's central table joined with its dimension tables (one row per source record x dimension combination, all columns read as character so identifiers and date stamps survive verbatim).
- Programs in `code/modules/04_panels/rcrainfo/` build the facility panels under `output/panels/` (all link `FRS_ID` from the manual FRS file):
  - `01_panel_2015_2023_balanced.R` — balanced facility-cycle panel (`BR_PANEL_2015_2023_BALANCED.csv`) of handlers recognized in the National Biennial Report as LQG and/or TSDF in **all five** cycles 2015-2023; Biennial Report status/tonnage columns plus duration-dominant handler attributes and a same-year conflict audit column from `HD_MASTER`.
  - `01_panel_2015_2023_balanced_summary.R` — descriptive summaries of the balanced panel (numeric and categorical), written to `output/panels/summary/` as CSVs and a two-sheet workbook.
  - `02_panel_eval_2015_2023.R` — balanced facility-month panel (`CE_PANEL_2015_2023.csv`) of RCRA compliance evaluations from `CE_MASTER`, months 2015-01 - 2023-12, with per-month evaluation counts by type and violation indicators.
  - `03_panel_2015_2023_unbalanced.R` — unbalanced counterpart of the balanced panel (`BR_PANEL_2015_2023_UNBALANCED.csv`): every handler recognized as LQG and/or TSDF in **at least one** cycle, one row per qualifying cycle; a strict superset built by the same rules.
- `code/utils/br_summary_paste.R` — convenience utility (not part of the pipeline): rebuilds a Biennial Report summary workbook as rich HTML on the macOS clipboard for pasting into Google Docs.
- `resources/` — reference documents (not used by the code): EPA RCRA notification/reporting forms (`epa_forms/`) and RCRAInfo module structure charts (`rcrainfo_modular_structure_charts/`).
- Output folders are created automatically; raw data folders are excluded from version control via `.gitignore`, while summary workbooks and the BR panels in `output/` are committed.

### License for Code

The code is licensed under the terms in `LICENSE`.

## Instructions to Replicators

1. Install R (4.4.2 or later) and the packages listed above, e.g. `install.packages(c("rvest", "xml2", "jsonlite", "tidyverse", "lubridate", "openxlsx2"))`.
2. Download the FRS national Program Links file (see source 9) and place it at `data/frs/FRS_PROGRAM_LINKS.csv` (required by the panel stage only).
3. From the repository root, run:

   ```sh
   Rscript code/master.R
   ```

4. All datasets and data dictionaries appear under `data/`; summary workbooks under `output/summary_tables/`; module master files under `output/modular_master_files/`; panels under `output/panels/`. Individual module scripts can also be run on their own (from the repository root), e.g. `Rscript code/modules/01_download/rcrainfo/01_download_data.R`.
5. If the run ends with DMR reporting that it was throttled, re-run `Rscript code/modules/01_download/dmr/01_download_data.R` on later days until it reports done; completed files are skipped (see source 8).

Note: because EPA refreshes these data on rolling schedules, downloaded files will reflect the current release, not necessarily the vintage documented above.

## References

- U.S. Environmental Protection Agency (2026a). "RCRA Pipeline Dataset." Enforcement and Compliance History Online (ECHO). https://echo.epa.gov/tools/data-downloads (accessed 2026-07-06).
- U.S. Environmental Protection Agency (2026b). "RCRAInfo Dataset." Enforcement and Compliance History Online (ECHO). https://echo.epa.gov/tools/data-downloads (accessed 2026-07-06).
- U.S. Environmental Protection Agency (2026c). "RCRAInfo CSV Downloads." Hazardous Waste Information Platform (HWIP). https://rcrapublic.epa.gov/rcra-hwip/data-access/csv-downloads (accessed 2026-07-06).
- U.S. Environmental Protection Agency (2026d). "RCRAInfo Public Data Element Dictionary." https://rcrainfo.epa.gov/rcrainfo-help/application/publicHelp/index.htm (accessed 2026-07-06).
- U.S. Environmental Protection Agency (2026e). "TRI Basic Plus Data Files: Calendar Years 1987-Present." https://www.epa.gov/toxics-release-inventory-tri-program/tri-basic-plus-data-files-calendar-years-1987-present (accessed 2026-07-08).
- U.S. Environmental Protection Agency (2026f). "National Emissions Inventory (NEI) Point-Source Extracts." EPA ORD Data Commons. https://dmap-data-commons-ord.s3.amazonaws.com/ (accessed 2026-07-08).
- U.S. Environmental Protection Agency (2026g). "Greenhouse Gas Reporting Program (GHGRP) Data Sets and Envirofacts." https://www.epa.gov/ghgreporting/data-sets and https://data.epa.gov/efservice/ (accessed 2026-07-08).
- U.S. Environmental Protection Agency (2026h). "Emissions & Generation Resource Integrated Database (eGRID)." https://www.epa.gov/egrid (accessed 2026-07-08).
- U.S. Environmental Protection Agency (2026i). "Water Pollutant Loading Tool (DMR REST Services)." Enforcement and Compliance History Online (ECHO). https://echodata.epa.gov/ (accessed 2026-07-08).
- U.S. Environmental Protection Agency (2026j). "Facility Registry Service (FRS) Data Resources." https://www.epa.gov/frs/frs-data-resources (accessed 2026-07-09).
- U.S. Environmental Protection Agency. "StEWI: Standardized Emission and Waste Inventories." https://github.com/USEPA/standardizedinventories (download logic reference for sources 4-8).

## Acknowledgements

This README follows the template of the Social Science Data Editors (https://social-science-data-editors.github.io/template_README/). The download scripts for TRI, NEI, GHGRP, eGRID, and DMR port the download step of EPA's open-source StEWI package (USEPA/standardizedinventories) to R.
