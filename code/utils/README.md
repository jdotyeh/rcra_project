# Utilities

Helper scripts that support the project but are **not** part of the replication
pipeline. `code/master.R` does not run anything in this folder.

## `summary_tables_to_html.R`

Compiles the summary-table workbooks in `output/summary_tables/` into two
standalone HTML files that live alongside them.

- `Modular Summary Tables.html` gathers the seven module workbooks (Handler,
  CME, Corrective Action, Permitting, Financial Assurance, and the WIETS
  exports and imports modules).
- `Biennial Report Summary Tables.html` gathers the twelve Biennial Report
  cycles from 2001 through 2023.

Every sheet of every workbook (Categorical, Quantitative, Dummy) is rebuilt as
an HTML table that mirrors the workbook's house format, so the fills, merged
variable blocks, gray descriptions, borders, alignment, and trailing note
blocks all carry over. Each file opens with a table of contents whose links
jump straight to a workbook or to one of its individual tables, and every
heading carries a "back to top" link. A floating button in the corner returns
to the top from anywhere on the page.

### How to run

Run from the repository root after the workbooks have been built by
`code/modules/04_summary_tables/`.

```sh
Rscript code/utils/summary_tables_to_html.R
```

With no argument the script writes both files. Pass `modular` or `br` to build
only one of them.

```sh
Rscript code/utils/summary_tables_to_html.R br
```

### Notes

- The workbooks must already exist in `output/summary_tables/`. A workbook that
  is missing is reported and skipped rather than treated as an error.
- The only dependency is `openxlsx2`. The output is self-contained HTML with
  inline styles, so it opens in any browser without other files.

## `build_site.R`

Assembles the public-facing project website into a top-level `docs/` folder,
built entirely from artifacts the pipeline already produces so that it never
drifts from a separately maintained copy. GitHub Pages can serve the folder
directly, and because every page is self-contained it also opens by
double-clicking `docs/index.html`.

The build writes four things.

- `docs/index.html` is the front door, an overview of the project with its
  four-stage pipeline, its nine EPA data sources, and a link to each output.
- `docs/state-reporting.html` is a searchable state-by-state reference of how
  hazardous-waste reporting works, rendered from `resources/table.md` and
  regenerated to match however many states that file currently covers.
- `docs/summary-tables/` receives the two compiled summary-table pages
  (`modular.html` and `biennial-report.html`), copied in from
  `output/summary_tables/` so that GitHub Pages can serve them.
- `docs/assets/site.css` is the one shared stylesheet, a clean institutional
  design that pairs a serif display face with a sans-serif body. The body text
  is loaded as a webfont when the reader is online and falls back to system
  fonts otherwise.

The footer carries a horizontal UVA Batten School monogram as the site's
identity. It is drawn inline as an SVG lockup in the script, so an official
brand asset can be dropped in there if one is preferred.

Like the script above, this one is not part of the replication pipeline and adds
no dependency beyond base R, so `code/master.R` never runs it.

### How to run

Run from the repository root after the summary-table workbooks and their
compiled pages (built by `summary_tables_to_html.R`) already exist.

```sh
Rscript code/utils/build_site.R
```

With no argument the script builds the whole site. Pass `state` to rebuild only
the state-reporting page while you are editing `resources/table.md`, or `index`
to rebuild only the front page.

### Publishing

Enable GitHub Pages on the default branch with the `/docs` folder as the source.
The site then serves at `https://<user>.github.io/rcra_project/`. Nothing else is
required, and no continuous-integration workflow is involved.

### Notes

- The two summary-table pages are copied in when present. A page that is missing
  is reported and skipped, so the rest of the site still builds.
- The state-reporting page adapts to `resources/table.md` as it grows, so
  finishing the remaining states needs no change to the script.
- The pages carry inline links to the repository and its README, so a reader can
  move from the overview straight to the code and the replication instructions.
