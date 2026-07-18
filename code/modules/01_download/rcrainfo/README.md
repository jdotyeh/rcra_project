# rcrainfo Download

Note: This folder has been verified.

This source is the complete set of RCRAInfo module tables from the EPA Hazardous
Waste Information Platform, covering the Biennial Report, Corrective Action,
Compliance Monitoring and Enforcement, e-Manifest, Financial Assurance, Handler,
Permitting, and WIETS modules. These tables are the backbone of the summary,
master file, and panel stages.

`01_download_data.R` reads the platform download API to find the current archive
links, downloads each archive, unzips it, and appends any numbered part files into
one CSV per table. The result is written under `data/rcrainfo/`, with one lower
case folder per module. `02_scrape_data_dictionary.R` reads the RCRAInfo public
data dictionary help pages and writes one markdown dictionary per module next to
the data.

Run the two scripts in order, download first and dictionary second. The master
script does this automatically. The archives are large, several gigabytes zipped
and tens of gigabytes unzipped, so a full download takes a while.
