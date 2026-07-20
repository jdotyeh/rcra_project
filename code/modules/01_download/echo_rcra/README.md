# echo_rcra Download

Note: This folder has been verified (Jul 17).

This source is the EPA ECHO RCRAInfo dataset, a compliance and enforcement extract
for hazardous waste sites that covers facilities, evaluations, violations,
violation and significant noncomplier history, enforcements, and NAICS codes.

`01_download_data.R` downloads the dataset archive, unzips it into
`data/echo_rcra/`, and removes the archive. `02_scrape_data_dictionary.R` reads
the EPA download summary page and writes a markdown data dictionary and a markdown
copy of the bundled read me next to the data.

Run the two scripts in order, download first and dictionary second. The master
script does this automatically.
