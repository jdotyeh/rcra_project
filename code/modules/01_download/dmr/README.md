# dmr Download

This source is the EPA Discharge Monitoring Report annual pollutant loadings,
reporting years 2014 through 2023.

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
throttled, so running it again on a later day resumes where it stopped. The master
script simply continues past it.

The downloaded files are documented in
[data/dmr/README.md](../../../../data/dmr/README.md).
