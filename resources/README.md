# Resources

Reference material that supports the project. Most of it is not read by the
pipeline, with the exceptions noted below that the public-site builder and the
enforcement panel read.

- `CE-Enforcement-Type.md` reproduces the RCRAInfo Nationally-Defined Values
  page for Enforcement Type, listing the 37 nationally-defined codes with their
  names, full definitions, and the page's own "Formal Action" flag. It is the
  single source of truth for which enforcement type codes count as defined, and
  `code/modules/03_panels/rcrainfo/04_panel_enf_2015_2023.R` reads it through
  `read_enf_type_defined()`.
- `CE-Enforcement-Type-Crosswalk.md` records how every state-specific
  enforcement type code in `CE_MASTER` was matched to a defined code, keyed on
  the code and the description together and using 999 for a pair that no defined
  code covers. Each line also carries a revised reading of the description in
  title case with its abbreviations expanded, and the file's abbreviation table
  records what each removed abbreviation stood for. A table of its own gathers
  the 53 pairs that land on 999 while still carrying a description, which is the
  part of the 999 group that can be read at all. It is a decision record as
  much as a lookup, explaining how each match was reached, and the same panel
  script reads it through
  `read_enf_type_crosswalk()`. Editing this file changes the panel, so the
  bullet format under its "Mapping" heading has to be kept.

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
  [state authorization brief](../docs/institutional_briefs/04_state_authorization.md), and
  `code/utils/build_site.R` renders it into the public site as a searchable page.
- `batten-logo.png` is the institutional logo the public site places in its
  footer.
