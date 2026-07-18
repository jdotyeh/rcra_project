# Modular Master Files

One analysis-ready master CSV per RCRAInfo module, built by
`code/modules/02_modular_master_files/`. Each file is the module's central table
joined to its dimension tables, with every column read as text so that
identifiers and date stamps survive exactly as reported. Binary indicators are
recoded from Y/N to 1/0, and Handler activity flags whose "N" predates the
flag's existence carry the unknown code "U"; the recode rules and the unit of
analysis of each master are documented in the
[module README](../../code/modules/02_modular_master_files/rcrainfo/README.md).
These files are large and are rebuilt by the code rather than committed to the
repository.

| File | Module | Notes |
|------|--------|-------|
| `HD_MASTER.csv` | Handler | The largest master, and the source of handler attributes for the panels. |
| `CE_MASTER.csv` | Compliance Monitoring and Enforcement | The source of the evaluation and enforcement panels. |
| `CA_MASTER.csv` | Corrective Action | Event-level cleanup record. |
| `PM_MASTER.csv` | Permitting | Permit and closure events. |
| `FA_MASTER.csv` | Financial Assurance | Cost estimates joined to funding mechanisms. |
| `WT_EXPORTS_MASTER.csv` | Waste export | Export notices joined to their dimensions. |
| `WT_IMPORTS_MASTER.csv` | Waste import | Import notices joined to their dimensions. |

Because a central record is crossed with several dimensions, one source record
expands into many rows, so a row is a record-by-dimension combination rather than
a facility. The [institutional briefs](../../docs/institutional/README.md) explain
what each module represents.
