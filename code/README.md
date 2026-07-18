# Code

This folder holds every script that builds the project. The work is organized as
a short pipeline of numbered stages, and a single master script runs the whole
thing from start to finish.

## Running everything

From the repository root, run `Rscript code/master.R`. The master script finds
every script under `code/modules/` and sources them in path order, so the setup
step runs first and the four numbered stages follow in sequence. Each script runs
in its own environment so that one cannot disturb another. A full pass downloads
tens of gigabytes and takes several hours.

## Layout

The `modules/` folder contains the pipeline itself, one subfolder per stage.

- `00_setup` installs and loads the R packages the pipeline needs and creates the
  output folders that later stages write into.
- `01_download` downloads the three raw RCRA data sources and scrapes the
  matching data dictionaries. It has one subfolder per data source.
- `02_modular_master_files` joins each RCRAInfo module into one analysis ready
  master file.
- `03_panels` builds facility panels from the master files and the Biennial
  Report.
- `04_summary_tables` builds a variable level summary workbook for the central
  table of each RCRAInfo module and for each Biennial Report cycle.

The `diagnostics/` folder holds download scripts for five supplementary EPA
inventories (TRI, NEI, GHGRP, eGRID, DMR) that are useful for extracting more
information about the panel facilities but sit outside the pipeline, so the
master script never runs them. See [diagnostics/README.md](diagnostics/README.md).

The `utils/` folder holds convenience scripts that support the project but are not
part of the pipeline, so the master script never runs them. See
[utils/README.md](utils/README.md).

## Documentation

Every module folder carries its own README that explains what the module does,
the scripts it contains, and the files it reads and writes. Start with the module
you are interested in. The replication instructions, data sources, and software
requirements for the whole project live in the [root README](../README.md). For
what the program terms mean and how they shape the data, see the
[institutional briefs](../docs/institutional/README.md).
