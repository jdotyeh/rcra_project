# DMR Data

EPA Discharge Monitoring Report (DMR) annual pollutant-loading data, pulled from
the ECHO Loading Tool API by `code/modules/01_download/dmr/01_download_data.R`.
One folder per reporting year (the year is in the folder path, not the file
name), plus a couple of files in this root. Kept raw as returned by the API.

In this root:

| File | What it includes |
|------|------------------|
| `DMR_POLLUTANTS.csv` | Reference list of DMR pollutant parameters (one copy for all years). |

In each year folder:

| File | What it includes |
|------|------------------|
| `DMR_LOADS_<state>.csv` | Annual pollutant discharge loads for the state, all pollutant groups. |
| `DMR_NITROGEN_<state>.csv` | Nitrogen nutrient-aggregated annual loads for the state. |
| `DMR_PHOSPHORUS_<state>.csv` | Phosphorus nutrient-aggregated annual loads for the state. |
| `DMR_TOTALS.csv` | State-level discharge totals for that year (used later for validation). |

`<state>` is the two-letter state/territory code.
