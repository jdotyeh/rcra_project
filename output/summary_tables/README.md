# Summary Tables

Variable-level summary workbooks, built by `code/modules/04_summary_tables/`. Each
workbook describes one table variable by variable, with categorical frequencies,
quantitative ranges, and yes-or-no indicator counts, in a fixed house format.
These files are small and are committed to the repository.

The seven module workbooks, one per RCRAInfo module central table:

| File | Central table |
|------|---------------|
| `Handler Module Summary Tables.xlsx` | HD_REPORTING |
| `CME Module Summary Tables.xlsx` | CE_REPORTING |
| `Corrective Action Module Summary Tables.xlsx` | CA_EVENT |
| `Permitting Module Summary Tables.xlsx` | PM_EVENT |
| `Financial Assurance Module Summary Tables.xlsx` | FA_COST_ESTIMATE |
| `WIETS Exports Module Summary Tables.xlsx` | WT_NOTICES_EXPORTS |
| `WIETS Imports Module Summary Tables.xlsx` | WT_NOTICES_IMPORTS |

The twelve cycle workbooks, `Biennial Report <cycle> Summary Tables.xlsx` for each
odd year from 2001 through 2023, each summarizing that cycle's BR_REPORTING
table.

Two compiled HTML pages sit alongside the workbooks. `Modular Summary Tables.html`
gathers the module workbooks and `Biennial Report Summary Tables.html` gathers the
cycle workbooks, each with a linked table of contents. They are produced by
`code/utils/summary_tables_to_html.R`, which is a convenience tool outside the
pipeline, and they are the files the public site serves.
