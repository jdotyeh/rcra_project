# Resource Conservation and Recovery Act (RCRA) Regulatory Infrastructure

## Overview

The code in this package downloads and documents hazardous waste compliance and enforcement data under the Resource Conservation and Recovery Act (RCRA) from two EPA platforms: ECHO (Enforcement and Compliance History Online) and RCRAInfo (via the Hazardous Waste Information Platform, HWIP). One master script runs all download modules from beginning to end. Each module downloads its raw data and scrapes the corresponding data dictionary from the EPA documentation pages. The replicator should expect the code to run for roughly 30 minutes to 2 hours, depending on connection speed, and to use about 40 GB of disk space.

## Data Availability and Provenance Statements

All data used in this project are public U.S. federal government data published by the EPA. The raw data files are not committed to this repository because of their size (about 40 GB unzipped); they are fully reproducible by running the code, which downloads the current release of each dataset.

Note that EPA refreshes these datasets on a rolling basis (ECHO weekly, HWIP exports weekly with dated snapshot paths), so a later run will download a newer vintage than the one described below. The data used here were exported by EPA on 2026-07-05 and downloaded on 2026-07-06.

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

Each `data/rcrainfo/<module>/` folder also contains EPA's `METADATA.txt` (record counts) and a scraped `<MODULE>_DATA_DICTIONARY.md`.

## Computational requirements

### Software Requirements

- R 4.4.2
  - `rvest` (1.0.5)
  - `xml2` (1.4.0)
  - `jsonlite` (2.0.0)
- An internet connection is required: all data are downloaded at run time.

### Controlled Randomness

- [x] No Pseudo random generator is used in the analysis described here.

### Memory, Runtime, Storage Requirements

#### Summary time to reproduce

Approximate time needed to reproduce the analyses on a standard (2026) desktop machine:

- [x] 10-60 minutes (fast connection) to 1-2 hours (slower connection); dominated by ~4.5 GB of downloads

#### Summary of required storage space

Approximate storage space needed:

- [x] 25 GB - 250 GB (about 40 GB after unzipping)

Memory requirements are minimal: files are streamed to disk and appended in chunks, not loaded into memory.

#### Computational Details

The code was last run on an **Apple M3 Pro laptop (18 GB RAM) with macOS 26.5.2** on 2026-07-06.

## Description of programs/code

- `code/master.R` runs every module script in order. It discovers all `.R` files under `code/modules/` and sources them in alphabetical path order, each in its own environment.
- Programs in `code/modules/01_download/` download the raw data and scrape the data dictionaries. Each module folder contains:
  - `01_download_data.R` - downloads the zip file(s), unzips them into the module's `data/` folder, deletes the zips, and (where applicable) renames files and appends numbered part files into one CSV per table.
  - `02_scrape_data_dictionary.R` - scrapes the EPA documentation page(s) for that dataset and writes markdown data dictionaries (and READ ME files) next to the data.
- Modules: `echo_rcra_pipeline` (ECHO RCRA pipeline), `echo_rcra` (ECHO RCRAInfo extract), `rcrainfo` (HWIP CSV exports for all RCRAInfo modules).
- Output data folders are created automatically and are excluded from version control via `.gitignore`.

### License for Code

The code is licensed under the terms in `LICENSE`.

## Instructions to Replicators

1. Install R (4.4.2 or later) and the packages listed above, e.g. `install.packages(c("rvest", "xml2", "jsonlite"))`.
2. From the repository root, run:

   ```sh
   Rscript code/master.R
   ```

3. All datasets and data dictionaries appear under `data/`. Individual module scripts can also be run on their own (from the repository root), e.g. `Rscript code/modules/01_download/rcrainfo/01_download_data.R`.

Note: because EPA refreshes these data weekly, downloaded files will reflect the current release, not necessarily the vintage documented above.

## References

- U.S. Environmental Protection Agency (2026a). "RCRA Pipeline Dataset." Enforcement and Compliance History Online (ECHO). https://echo.epa.gov/tools/data-downloads (accessed 2026-07-06).
- U.S. Environmental Protection Agency (2026b). "RCRAInfo Dataset." Enforcement and Compliance History Online (ECHO). https://echo.epa.gov/tools/data-downloads (accessed 2026-07-06).
- U.S. Environmental Protection Agency (2026c). "RCRAInfo CSV Downloads." Hazardous Waste Information Platform (HWIP). https://rcrapublic.epa.gov/rcra-hwip/data-access/csv-downloads (accessed 2026-07-06).
- U.S. Environmental Protection Agency (2026d). "RCRAInfo Public Data Element Dictionary." https://rcrainfo.epa.gov/rcrainfo-help/application/publicHelp/index.htm (accessed 2026-07-06).

## Acknowledgements

This README follows the template of the Social Science Data Editors (https://social-science-data-editors.github.io/template_README/).
