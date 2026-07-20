# Summary Tables

Variable-level summary workbooks, built by `code/modules/04_summary_tables/`. Each
workbook describes one table variable by variable, with categorical frequencies,
quantitative ranges, and yes-or-no indicator counts, in a fixed house format.
These files are small and are committed to the repository.

The seven module workbooks, one per RCRAInfo module master file:

| File | Master file |
|------|-------------|
| `Handler Module Summary Tables.xlsx` | HD_MASTER |
| `CME Module Summary Tables.xlsx` | CE_MASTER |
| `Corrective Action Module Summary Tables.xlsx` | CA_MASTER |
| `Permitting Module Summary Tables.xlsx` | PM_MASTER |
| `Financial Assurance Module Summary Tables.xlsx` | FA_MASTER |
| `WIETS Exports Module Summary Tables.xlsx` | WT_EXPORTS_MASTER |
| `WIETS Imports Module Summary Tables.xlsx` | WT_IMPORTS_MASTER |

Each module workbook covers every column of its master file that carries a
coded, dated, numeric, or indicator value. Record identifiers, personal names
and staff identifiers, correspondence addresses and contact details, free-text
notes, and the description text paired with a summarized code are left out and
named in a note block under the Categorical table.

The twelve cycle workbooks, `Biennial Report <cycle> Summary Tables.xlsx` for each
odd year from 2001 through 2023, each summarizing that cycle's BR_REPORTING
table.

Two compiled HTML pages sit alongside the workbooks. `Modular Summary Tables.html`
gathers the module workbooks and `Biennial Report Summary Tables.html` gathers the
cycle workbooks, each with a linked table of contents. They are produced by
`code/utils/summary_tables_to_html.R`, which is a convenience tool outside the
pipeline, and they are the files the public site serves.
