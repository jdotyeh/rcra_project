# echo_rcra_pipeline Download

Note: This folder has been verified.

This source is the EPA ECHO RCRA pipeline dataset, which records compliance
monitoring activities (CMAs) together with the violations and enforcement actions linked
to them. This dataset is currently limited to CMAs and violations from the past 10 years,
plus older violations that remain unresolved.

`01_download_data.R` downloads the archive, unzips it into
`data/echo_rcra_pipeline/`, renames the tables to names that begin with
`PIPELINE_`, and converts the bundled read me to markdown.
`02_scrape_data_dictionary.R` reads the EPA summary page and writes the markdown
data dictionary next to the data.

Run the two scripts in order, download first and dictionary second. The master
script does this automatically.
