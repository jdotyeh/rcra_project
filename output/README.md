# Output

This folder holds everything the pipeline derives from the raw data. Unlike
`data/`, some of it is committed to the repository, because the summary workbooks
and the panels are small and useful to have on hand.

- `summary_tables/` holds the variable-level summary workbooks, one per RCRAInfo
  module and one per Biennial Report cycle, plus two compiled HTML pages. These
  are built by `code/modules/04_summary_tables/` and the HTML utility, and they
  are committed.
- `modular_master_files/` holds one analysis-ready master CSV per RCRAInfo module.
  These are built by `code/modules/02_modular_master_files/`, are large, and are
  rebuilt rather than committed.
- `panels/` holds the facility panels and their summaries. These are built by
  `code/modules/03_panels/`, are small, and are committed.

Each subfolder carries its own README with the details.
