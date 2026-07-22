# 03_panels

Note: This folder has been verified (Jul 19).

This stage builds facility panels from the module master files and the Biennial
Report. Every panel attaches the EPA FRS identifier by
linking the RCRAInfo handler identifier through the Program Links file, which
the download stage's `frs` module downloads into `data/frs/`.

## Building just the panels

`build_panels.R` is a shortcut that builds the panels end to end without running
the rest of the project. From the repository root, run

```sh
Rscript code/modules/03_panels/rcrainfo/build_panels.R
```

It runs setup, downloads the FRS Program Links and Facilities files and the
RCRAInfo tables only if the raw inputs are missing, builds the Handler and
Compliance master files only if they are missing, and then builds the five
panels. It does not run the
descriptive summary script, which is optional and can be run on its own
afterward. The full-project master script, `code/master.R`, also builds the
panels as its final stage and deliberately skips this shortcut so the work is
not done twice.

## Scripts

The build logic lives in shared functions, and each panel script sets its
parameters and calls them.

`00_panel_functions.R` defines every shared function. Running it on its own only
defines them. The generic helpers serve all five panels: `read_frs_links()`
attaches the FRS identifier, `join_distinct()` and
`last_known()` collapse multi-valued fields, and `write_panel()` writes a panel
CSV with an optional typed `.rds` twin. Two further helpers serve the enforcement
panel alone: `read_enf_type_defined()` and `read_enf_type_crosswalk()` read the
enforcement type reference and its state-specific crosswalk out of `resources/`,
so the list of defined codes and the matching decisions live in those files
rather than in the script. The Biennial Report machinery, ending in
`build_br_panel()`, builds the facility-cycle panels, and its three-tier
conflict-resolution design is documented in the file.

`01_panel_2015_2023_balanced.R` runs `build_br_panel(balanced = TRUE)`: the
balanced facility cycle panel of handlers recognized in the Biennial Report as
LQGs or as TSDFs in all five cycles from 2015 through 2023. Its header documents
the panel column by column. `02_panel_2015_2023_unbalanced.R` runs the same
builder with `balanced = FALSE`, keeping every handler recognized in at least one
cycle, a strict superset built by the same rules.

`03_panel_eval_2015_2023.R` builds a balanced facility month panel of compliance
evaluations from the Compliance master file, `04_panel_enf_2015_2023.R` builds
the matching facility month panel of enforcement actions, and
`05_panel_viol_2015_2023.R` builds the facility month panel of violations, all
three from the same master file and all covering every month from January 2015
through December 2023. Their month-level aggregation rules are the substance of
each script; the shared helpers handle the FRS link and the writing. The three
panels anchor a record to a different date, the evaluation start date, the
enforcement action date, and the date the violation was determined, so a single
inspection and the violations it produced can land in different months.

`01_panel_2015_2023_balanced_summary.R` produces descriptive numeric and
categorical summaries of the balanced panel, and it runs after the balanced panel
exists.

## What it reads and writes

The panels read the Biennial Report tables under `data/rcrainfo/br/`, the Handler
and Compliance master files under `output/modular_master_files/`, and
`data/frs/FRS_PROGRAM_LINKS.csv`. The enforcement panel also reads
`resources/CME-Enforcement-Type.md` and
`resources/CME-Enforcement-Type-Crosswalk.md`. Each panel is written under `output/panels/` in
its own subfolder, and every panel subfolder carries a README that documents the
panel column by column. The panels are small enough to be committed with the
repository.

## Institutional context

The panels are shaped by program rules, and three of them matter most. The
Biennial Report covers odd-numbered data years, which is why the cycles are 2015,
2017, 2019, 2021, and 2023 and why the code classifies a handler into a cycle by
its report cycle. The definitions of an LQG and of a TSDF decide who enters the
balanced and unbalanced panels. The division of authority between EPA and the
states is why the enforcement panel splits actions into state and federal and why
organizational codes keep their state prefix. These points are developed in the
[biennial report](../../../../docs/institutional_briefs/01_biennial_report.md),
[generators and handlers](../../../../docs/institutional_briefs/02_generators_and_handlers.md),
[compliance and enforcement](../../../../docs/institutional_briefs/03_compliance_and_enforcement.md),
and [state authorization](../../../../docs/institutional_briefs/04_state_authorization.md)
briefs. One consequence worth keeping in view is that states differ in who must
file a Biennial Report, so counts of reporting facilities are not directly
comparable across state lines.

## Running

The master script runs the whole stage. To rebuild one panel, run its script from
the repository root, for example
`Rscript code/modules/03_panels/rcrainfo/01_panel_2015_2023_balanced.R`. The
balanced panel must exist before its summary script runs.
