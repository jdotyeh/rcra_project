# Resources

Reference material that supports the project. Most of it is not read by the
pipeline, with two exceptions noted below that the public-site builder uses.

- `epa_forms/` holds the EPA notification and reporting forms that generate the
  underlying records, including Form 8700-12 for notification of activity, Form
  8700-13 A and B for the Biennial Report, Form 8700-23 for the permit
  application, and the RCRA Subtitle C reporting instructions. These are useful
  for reading a column back to the box on the form that produced it.
- `rcrainfo_modular_structure_charts/` holds one EPA structure chart per RCRAInfo
  module (`Structure Chart - CA.pdf`, and likewise CE, EM, FA, HD, PM, and WT),
  showing how a module's central table relates to its dimension tables. These are
  a helpful map when reading the master-file joins in
  `code/modules/02_modular_master_files/`.
- `table.md` is a state-by-state reference of how hazardous waste reporting works,
  covering who must report, on what schedule, through which system, and under
  which state-specific waste codes. It is the source for the
  [state authorization brief](../docs/institutional/04_state_authorization.md), and
  `code/utils/build_site.R` renders it into the public site as a searchable page.
- `batten-logo.png` is the institutional logo the public site places in its
  footer.
