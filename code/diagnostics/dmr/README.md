# dmr Download

This inventory is the EPA Discharge Monitoring Report (DMR) annual pollutant
loadings, reporting years 2014 through 2023. It is not part of the pipeline; see
the [diagnostics README](../README.md) for how these inventories are meant to be
used.

`01_download_data.R` queries the ECHO Loading Tool REST API one state at a time,
because there is no bulk file to download. For each state and year it saves the
annual loads along with nitrogen and phosphorus aggregated variants, and it also
saves the pollutant parameter list and the per year state totals that are used
later for validation. The files are kept exactly as the API returns them and are
written under `data/dmr/`, one folder per year. The list of states the script
iterates over comes from `state_codes.csv`, which sits next to the script.

The ECHO service caps clients at three hundred requests an hour and fifteen
hundred a day, so a full ten year pull spans several days. The script paces its
requests, skips any file it has already downloaded, and exits cleanly when it is
throttled, so running it again on a later day resumes where it stopped.

The download produces, in the `data/dmr/` root:

| File | What it includes |
|------|------------------|
| `DMR_POLLUTANTS.csv` | Reference list of DMR pollutant parameters (one copy for all years). |

And in each year folder:

| File | What it includes |
|------|------------------|
| `DMR_LOADS_<state>.csv` | Annual pollutant discharge loads for the state, all pollutant groups. |
| `DMR_NITROGEN_<state>.csv` | Nitrogen nutrient-aggregated annual loads for the state. |
| `DMR_PHOSPHORUS_<state>.csv` | Phosphorus nutrient-aggregated annual loads for the state. |
| `DMR_TOTALS.csv` | State-level discharge totals for that year (used later for validation). |

`<state>` is the two-letter state/territory code.
