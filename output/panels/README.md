# Panels

The facility panels, built by `code/modules/03_panels/`. These are the analytical
endpoint of the project, and they are small enough to be committed to the
repository. Each panel lives in a subfolder and carries its own decision record
documenting it column by column.

- `BR_PANEL_2015_2023_BALANCED/` is the balanced facility-cycle panel of handlers
  recognized as an LQG or a TSDF in all five Biennial Report cycles from 2015
  through 2023.
- `BR_PANEL_2015_2023_UNBALANCED/` is the unbalanced counterpart, which keeps a
  handler in any cycle where it was recognized.
- `CE_PANEL_2015_2023/` holds the three facility-month panels drawn from the
  Compliance Monitoring and Enforcement master, one of compliance evaluations,
  one of enforcement actions, and one of determined violations, each covering
  every month from January 2015 through December 2023 and each carrying its own
  decision record in the folder.
- `summary/` holds descriptive summaries of the balanced panel.

Every panel attaches a facility registry identifier through the FRS link. The
program facts behind the panels are in the
[biennial report](../../docs/institutional_briefs/01_biennial_report.md),
[generators and handlers](../../docs/institutional_briefs/02_generators_and_handlers.md),
and [compliance and enforcement](../../docs/institutional_briefs/03_compliance_and_enforcement.md)
briefs.
