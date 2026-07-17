# Panels

The facility panels, built by `code/modules/03_panels/`. These are the analytical
endpoint of the project, and they are small enough to be committed to the
repository. Each panel lives in its own subfolder with a README that documents it
column by column.

- `BR_PANEL_2015_2023_BALANCED/` is the balanced facility-cycle panel of handlers
  recognized as a large quantity generator or a treatment, storage, and disposal
  facility in all five Biennial Report cycles from 2015 through 2023.
- `BR_PANEL_2015_2023_UNBALANCED/` is the unbalanced counterpart, which keeps a
  handler in any cycle where it was recognized.
- `CE_PANEL_2015_2023/` holds the two facility-month panels drawn from the
  Compliance Monitoring and Enforcement master, one of compliance evaluations and
  one of enforcement actions, each covering every month from January 2015 through
  December 2023.
- `summary/` holds descriptive summaries of the balanced panel.

Every panel attaches a facility registry identifier through the Facility Registry
Service link. The program facts behind the panels are in the
[biennial report](../../docs/institutional/01_biennial_report.md),
[generators and handlers](../../docs/institutional/02_generators_and_handlers.md),
and [compliance and enforcement](../../docs/institutional/03_compliance_and_enforcement.md)
briefs.
