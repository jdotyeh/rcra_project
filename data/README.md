# Data

This folder holds the raw inputs the project is built on. Everything here is
downloaded from EPA by the scripts in `code/modules/01_download/`, with one manual
exception noted below, so the folder is reproduced rather than stored. The raw
files are large, roughly fifty gigabytes in total, and are not committed to the
repository.

There is one subfolder per data source.

- `echo_rcra/` and `echo_rcra_pipeline/` are the two EPA ECHO extracts of RCRA
  compliance and enforcement.
- `rcrainfo/` is the complete set of RCRAInfo module tables, the backbone of the
  analysis, with one lower-case folder per module.
- `tri/`, `nei/`, `ghgrp/`, `egrid/`, and `dmr/` are five supplementary EPA
  facility-level environmental datasets.
- `frs/` holds the one input that is not downloaded by code.

The Facility Registry Service Program Links file must be obtained by hand and
placed at `frs/FRS_PROGRAM_LINKS.csv`, and the panel stage uses it to attach
facility identifiers. The download instructions are in the
[download stage README](../code/modules/01_download/README.md), and the reason the
link matters is explained in the
[facility identifiers brief](../docs/institutional/09_facility_identifiers.md).

Most subfolders carry their own README that lists the files they hold, and each
RCRAInfo module folder also carries a scraped data dictionary. For the meaning of
the program terms behind these tables, see the
[institutional briefs](../docs/institutional/README.md).
