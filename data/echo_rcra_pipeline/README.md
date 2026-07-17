# echo_rcra_pipeline Data

The EPA ECHO RCRA pipeline extract, which records compliance monitoring activities
together with the violations and enforcement actions linked to them, downloaded by
`code/modules/01_download/echo_rcra_pipeline/01_download_data.R`. The files are
kept raw as downloaded and are renamed to names that begin with `PIPELINE_`.

| File | What it holds |
|------|---------------|
| `PIPELINE_00_COMPLETE.csv` | The full linked pipeline, one row per monitoring activity with its linked violation and enforcement fields. |
| `PIPELINE_01_EVALUATIONS.csv` | The evaluation side of the pipeline. |
| `PIPELINE_02_VIOLATIONS.csv` | The violation side of the pipeline. |
| `PIPELINE_03_ENFORCEMENT_ACTIONS.csv` | The enforcement-action side of the pipeline. |

Two documentation files accompany the data. `PIPELINE_DATA_DICTIONARY.md`
describes the columns, and `PIPELINE_READ_ME.md` is EPA's own note about the
extract, both written by `02_scrape_data_dictionary.R`.

The program terms behind these tables are covered in the
[compliance and enforcement brief](../../docs/institutional/03_compliance_and_enforcement.md).
