# Diagnostics

Download scripts for supplementary EPA data inventories that sit outside the
replication pipeline. The master script does not run anything in this folder, and
none of the pipeline stages read what these scripts download. They are kept
because they are useful data inventories for extracting more information about
the facilities in the panels, such as toxic releases, air emissions, greenhouse
gases, power-plant characteristics, and water discharges, and each can be joined
to the panels through facility identifiers.

There is one subfolder per inventory, and each has its own README with the
details.

- [tri](tri/README.md) is the Toxics Release Inventory Basic Plus files.
- [nei](nei/README.md) is the National Emissions Inventory point source data.
- [ghgrp](ghgrp/README.md) is the Greenhouse Gas Reporting Program.
- [egrid](egrid/README.md) is the Emissions and Generation Resource Integrated
  Database plant workbooks.
- [dmr](dmr/README.md) is the Discharge Monitoring Report annual pollutant
  loadings.

Each script downloads its inventory raw into `data/<inventory>/`, so running one
adds a folder there beyond the three core RCRA sources. The download scripts port
the download step of EPA's open-source StEWI package (USEPA/standardizedinventories)
to R against the current EPA endpoints.

To run one, from the repository root, for example:

```sh
Rscript code/diagnostics/tri/01_download_data.R
```
