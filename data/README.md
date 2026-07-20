# Data

This folder holds the raw inputs the project is built on. Everything here is
downloaded from EPA by the scripts in `code/modules/01_download/`, so the folder
is reproduced rather than stored. The raw files are large, roughly forty
gigabytes in total, and are not committed to the repository.

There is one subfolder per data source.

- `echo_rcra/` and `echo_rcra_pipeline/` are the two EPA ECHO extracts of RCRA
  compliance and enforcement.
- `rcrainfo/` is the complete set of RCRAInfo module tables, the backbone of the
  analysis, with one lower-case folder per module.
- `frs/` holds the FRS Program Links file, which the panel
  stage uses to attach facility identifiers; the reason the link matters is
  explained in the
  [facility identifiers brief](../docs/institutional/09_facility_identifiers.md).

Running an inventory script from `code/diagnostics/` adds its own folder here
(`tri/`, `nei/`, `ghgrp/`, `egrid/`, or `dmr/`); those supplementary inventories
sit outside the pipeline and are documented in the
[diagnostics README](../code/diagnostics/README.md).

Each subfolder carries its own README that lists the files it holds, and each
RCRAInfo module folder also carries a scraped data dictionary. For the meaning of
the program terms behind these tables, see the
[institutional briefs](../docs/institutional/README.md).
