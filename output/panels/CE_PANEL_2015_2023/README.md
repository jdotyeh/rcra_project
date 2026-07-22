# Compliance Monitoring and Enforcement Panels

The three facility-month panels drawn from `CE_MASTER.csv`, the compliance
monitoring and enforcement master file compiled from RCRAInfo's CM&E module.
They are built by `code/modules/03_panels/rcrainfo/`, and each is written as a
CSV with an `.rds` twin that carries the exact column types. They are too large
to commit, so the repository tracks only the documentation and the files
themselves are rebuilt by the code.

All three are keyed on `HANDLER_ID`, `YEAR`, and `MONTH`, all three are balanced
over the same 108 calendar months from January 2015 through December 2023, and
all three attach a facility registry identifier through the FRS link. They can
therefore be joined on the panel key. Their universes are not the same, because
each panel keeps the facilities that recorded the outcome it measures, so a join
across the files has to state which side it keeps.

Each panel has its own decision record beside it, documenting that panel alone.

- `EVAL_PANEL_2015_2023.csv` holds compliance evaluations, placed on the month
  an evaluation started, at 87,866 facilities. Its decision record is
  [`EVAL_PANEL_2015_2023_README.md`](EVAL_PANEL_2015_2023_README.md).
- `ENF_PANEL_2015_2023.csv` holds enforcement actions, placed on the month an
  action was issued, at 32,172 facilities. Its decision record is
  [`ENF_PANEL_2015_2023_README.md`](ENF_PANEL_2015_2023_README.md).
- `VIOL_PANEL_2015_2023.csv` holds determined violations, placed on the month a
  violation was determined, at 38,618 facilities. Its decision record is
  [`VIOL_PANEL_2015_2023_README.md`](VIOL_PANEL_2015_2023_README.md).

Because each panel anchors its records to a different date, a single inspection
and the violations and enforcement it produced can land in different months.

The program facts behind the three panels are in the
[compliance and enforcement](../../../docs/institutional_briefs/03_compliance_and_enforcement.md),
[state authorization](../../../docs/institutional_briefs/04_state_authorization.md),
and [facility identifiers](../../../docs/institutional_briefs/09_facility_identifiers.md)
briefs.
