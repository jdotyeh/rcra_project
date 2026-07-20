# `CE_PANEL_2015_2023` Decision Record #

## Purpose ##
This document records every construction decision behind `CE_PANEL_2015_2023.csv`, built by `code/modules/03_panels/rcrainfo/03_panel_eval_2015_2023.R`. Each decision states the outcome that was adopted, the details of how it is implemented, the considerations behind it where alternatives were worth weighing, and the measured impact on the data. Every count is taken from the actual input and output files, and every percentage states the baseline it is measured against. The decisions appear in the order in which they act on the data, so reading top to bottom follows the construction of the panel from `CE_MASTER.csv` to the final CSV.

## Construction Decisions ##

### Decision 1. Universe and Unit of Observation ###
- **Decision**
    - The panel is a balanced facility-month panel keyed on `HANDLER_ID`, `YEAR`, and `MONTH`. It covers the 108 calendar months from January 2015 through December 2023, and a facility is included if at least one of its compliance evaluations started in that window. Every included facility carries all 108 months.
- **Details**
    - Each facility-month represents one facility in one calendar month. Months are indexed by `YEAR` (2015-2023) and `MONTH` (1-12).
    - A facility contributes exactly 108 facility-months regardless of how many months hold an evaluation; months without one are zero-filled per Decision 7.
    - The source is `CE_MASTER.csv`, the compliance monitoring and enforcement master file compiled from RCRAInfo's CM&E module.
- **Considerations**
    - The monthly grain was chosen over an annual one because evaluations are dated events rather than period reports, and a month is fine enough to order events within a year while staying coarse enough that multi-evaluation cells are rare (Decision 6 counts them).
    - The balanced grid means absence of a row never has to be interpreted; a facility-month with nothing recorded exists in the panel and says so explicitly.
- **Impact**
    - `CE_MASTER.csv`: 2,872,361 records covering 306,739 distinct facilities, collapsing to 1,123,893 distinct evaluations (Decision 2).
    - Evaluations starting in 2015-2023: 202,501 (18.02% of the 1,123,893 distinct evaluations), at 87,866 distinct facilities (28.65% of the 306,739 facilities appearing in `CE_MASTER`).
    - Panel: 9,489,528 facility-months, exactly 87,866 facilities times 108 months.

### Decision 2. Evaluation Identity and Deduplication ###
- **Decision**
    - One evaluation is one distinct combination of `HANDLER_ID`, `EVAL_ACTIVITY_LOCATION`, `EVAL_IDENTIFIER`, `EVAL_START_DATE`, and `EVAL_AGENCY`, and every count in the panel is a count of these distinct evaluations.
- **Details**
    - `CE_MASTER.csv` repeats the evaluation key across its child records, so the same evaluation can appear on many rows. The panel collapses the file back to one row per evaluation before any counting.
    - `EVAL_IDENTIFIER` alone is not unique across agencies or locations, which is why the full five-column key defines identity.
- **Considerations**
    - Counting raw rows instead of distinct evaluations would inflate every panel count by whatever follow-on records an evaluation accumulated, and the inflation would correlate with exactly the outcomes a user is likely to study.
- **Impact**
    - The collapse takes 2,872,361 records to 1,123,893 evaluations (39.13% of the row count); an evaluation spans 2.56 records on average.

### Decision 3. Month Assignment ###
- **Decision**
    - An evaluation belongs to the calendar month of its `EVAL_START_DATE`, which the data dictionary defines as the first day of the inspection or record review regardless of its duration.
- **Details**
    - Evaluations whose start date cannot be parsed cannot be month-assigned and are excluded by construction. In the current data this exclusion is empty: all 1,123,893 distinct evaluations carry a parseable `EVAL_START_DATE`.
    - Evaluations starting outside 2015-2023 fall outside the panel window and are excluded.
- **Considerations**
    - The start date is the only date carried on every evaluation. The notice-of-compliance date exists on just 2.64 percent of window evaluations (Decision 6 keeps it as an outcome field), so anchoring months anywhere else would leave most evaluations unplaceable.
- **Impact**
    - Excluded for an unparseable date: 0 evaluations (0.00%).
    - Excluded as outside the window: 921,392 evaluations (81.98% of the 1,123,893 distinct evaluations).

### Decision 4. FRS Linkage ###
- **Decision**
    - Every facility-month carries `FRS_ID`, the EPA FRS `REGISTRY_ID`, so the panel can be joined to other EPA programs through a common facility identifier.
- **Details**
    - The link comes from the FRS Program Links file (`data/frs/FRS_PROGRAM_LINKS.csv`), matching the facility's RCRAInfo identifier (`HANDLER_ID`) against `PGM_SYS_ID` on the rows where `PGM_SYS_ACRNM == "RCRAINFO"`. The mapping is one-to-one from the handler to the registry identifier, so the join cannot fan out the panel.
    - The reverse direction is not injective. A registry identifier names a physical site, and a site that re-registered under RCRA carries every one of its handler identifiers on the same `FRS_ID`. In the evaluation panel 649 registry identifiers are shared by two or more handlers, 1,358 handlers in all (1.55 percent of the 87,866); the widest case is `FRS_ID` 110000618546, carried by eight Pennsylvania handler identifiers. The enforcement panel holds 158 shared registry identifiers covering 323 of its 32,172 handlers (1.00 percent). Analyses keyed on `FRS_ID` should expect these clusters rather than assume one handler per registry identifier.
    - The mapping was verified to be strictly one-to-one on the RCRAINFO rows. The file holds 1,591,859 RCRAINFO rows with 1,591,859 distinct `PGM_SYS_ID` values and zero identifiers mapped to more than one `REGISTRY_ID`, so the join cannot fan out the panel.
    - `FRS_ID` is empty when no RCRAINFO link exists for the facility.
- **Impact**
    - 87,799 of the 87,866 panel facilities (99.92%) link to an FRS registry ID. The unmatched remainder is 67 facilities (0.08%) covering 7,236 facility-months (0.08% of the 9,489,528 panel facility-months).

### Decision 5. Facility Attributes ###
- **Decision**
    - Four facility-level attributes are taken from the facility snapshot columns that ride on the evaluation records, fixed at one value per facility, and repeated across all 108 of its months.

      | Element | Source variable | Description |
      | --- | --- | --- |
      | `CE_ACTIVITY_STATE` | `HANDLER_ACTIVITY_LOCATION` | Location of the agency regulating the facility. |
      | `CE_LOCATION_STATE` | `STATE` | State postal code where the facility is located. |
      | `CE_EPA_REGION` | `REGION` | EPA region in which the facility is located. |
      | `CE_LAND_TYPE` | `LAND_TYPE` | Current ownership status of the land on which the facility is located. |

- **Details**
    - The value used is the last non-missing value in evaluation start-date order, so each attribute reflects the facility's most recent evaluation that recorded it.
    - These columns are snapshots carried on evaluation records, not a notification history, so they hold one value per facility rather than one per facility-month.
- **Considerations**
    - The attributes are constant within facility in the data except for 18 facilities (0.02% of 87,866) that carry two `HANDLER_ACTIVITY_LOCATION` values across their evaluations; the most-recent rule fixes those deterministically instead of leaving two competing values.
    - `LAND_TYPE` is blank on 4.51 percent of window evaluation records (9,123 of 202,501), which is why the rule takes the last non-missing value rather than the value on the latest record.
- **Impact**
    - `CE_LAND_TYPE` remains empty for 6,797 facilities (7.74% of 87,866) whose evaluations never record a land type; the other three attributes are filled for every facility.

### Decision 6. Elements Included from `CE_MASTER.csv` ###
- **Decision**
    - Each facility-month carries three groups of evaluation content: descriptive fields for the month's evaluations, count columns by evaluation type, and 0/1 indicator columns derived from the counts. All other `CE_MASTER` elements stay out of the panel.
- **Details**
    - Month-level descriptive fields, empty when the month has no evaluation.

      | Element | Source variable | Description |
      | --- | --- | --- |
      | `CE_EVAL_STATE` | `EVAL_ACTIVITY_LOCATION` | Location of the agency conducting the evaluation; distinct values in start-date order. |
      | `CE_EVAL_AGENCY` | `EVAL_AGENCY` | Agency responsible for conducting the evaluation; distinct values in start-date order. |
      | `CE_END_YEAR`, `CE_END_MONTH` | `NOC_DATE` | Year and month the facility was notified that no violations were discovered or that previously discovered violations returned to compliance. |

    - Count and indicator columns, 0 on months with no evaluation.

      | Element | Source rule | Description |
      | --- | --- | --- |
      | `CE_ANY_EVAL`, `CE_TOTAL_EVALS` | all evaluations | Evaluations starting in the month. |
      | `CE_ANY_CEI`, `CE_TOTAL_CEI` | `EVAL_TYPE == "CEI"` | Compliance evaluation inspections. |
      | `CE_ANY_NRR`, `CE_TOTAL_NRR` | `EVAL_TYPE == "NRR"` | Non-financial record reviews. |
      | `CE_ANY_FCI`, `CE_TOTAL_FCI` | `EVAL_TYPE == "FCI"` | Focused compliance inspections. |
      | `CE_ANY_SNY`, `CE_TOTAL_SNY` | `EVAL_TYPE == "SNY"` | Significant non-complier determinations. |
      | `CE_ANY_CSE`, `CE_TOTAL_CSE` | `EVAL_TYPE == "CSE"` | Compliance schedule evaluations. |
      | `CE_ANY_OTHER`, `CE_TOTAL_OTHER` | every other `EVAL_TYPE` | The remaining evaluation types (FRR, FSD, SNN, FUI, CAV, CDI, OAM, CAC, GME, NIR). |
      | `CE_ANY_VIOL`, `CE_EVALS_WITH_VIOL` | `FOUND_VIOLATION == "1"` | Evaluations that discovered violations at the facility; `CE_MASTER` codes the flag "1"/"0"/"U", and "0" and "U" (undetermined) do not count. |

    - Months holding more than one evaluation join the multi-valued descriptive fields with semicolons in evaluation start-date order, and the i-th `CE_END_YEAR` entry pairs with the i-th `CE_END_MONTH` entry.
    - Elements of `CE_MASTER.csv` not included in the panel, grouped, with the rationale for exclusion.

      | Elements | Description | Rationale |
      | --- | --- | --- |
      | `HANDLER_NAME` | Facility legal name. | The facility is already keyed by `HANDLER_ID` and `FRS_ID`. |
      | Child-record keys (`VIOL_SEQ`, `REQUEST_SEQ`, `CITATION_SEQ`, `CAFO_SEQ`, `SEP_SEQ`, `ENF_IDENTIFIER`) | Sequence numbers and identifiers of the records that repeat the evaluation key. | Record machinery, not facility-month content. |
      | Evaluation detail (`EVAL_TYPE_DESC`, `FOCUS_AREA`, `FOCUS_AREA_DESC`, `EVAL_RESPONSIBLE_PERSON`, `EVAL_SUBORGANIZATION`, `EVAL_LAST_CHANGE`, `CITIZEN_COMPLAINT`, `MULTIMEDIA_INSPECTION`, `SAMPLING`, `NOT_SUBTITLE_C`) | Type descriptions, focus areas, responsible staff codes, and context flags of the individual evaluation. | Evaluation-level detail beneath the month grain; recoverable by joining the evaluation key back to `CE_MASTER.csv`. |
      | Information-request fields (`DATE_OF_REQUEST`, `DATE_RESPONSE_RECEIVED`, `REQUEST_AGENCY`, `REQUEST_ACTIVITY_LOCATION`) | RCRA 3007 information requests attached to the evaluation. | Child records of the evaluation; recoverable by the same join. |
      | Violation fields (`VIOL_ACTIVITY_LOCATION`, `VIOL_TYPE`, `VIOL_TYPE_OWNER`, `VIOL_SHORT_DESC`, `DETERMINED_DATE`, `VIOL_DETERMINED_BY_AGENCY`, `RESPONSIBLE_AGENCY`, `SCHEDULED_COMPLIANCE_DATE`, `ACTUAL_RTC_DATE`, `RTC_QUALIFIER`, `CITATION`, `CITATION_OWNER`, `CITATION_TYPE`, `FORMER_CITATION`, `VIOL_LAST_CHANGE`) | Determined violations with their citations, compliance schedules, and return-to-compliance dates. | Child records of the evaluation; the facility-month keeps the evaluation-level `FOUND_VIOLATION` signal, and the detail is recoverable by the same join. |
      | Enforcement fields (`ENF_ACTIVITY_LOCATION`, `ENF_TYPE`, `ENF_TYPE_DESC`, `ENF_ACTION_DATE`, `ENF_AGENCY`, `DOCKET_NUMBER`, `ATTORNEY`, `ENF_RESPONSIBLE_PERSON`, `ENF_SUBORGANIZATION`, `CA_COMPONENT`, `FA_REQUIREMENT`, appeal and disposition fields, `RESPONDENT_NAME`, `LEAD_AGENCY`, `ENF_LAST_CHANGE`, `PROPOSED_AMOUNT`, `FINAL_MONETARY_AMOUNT`, `PAID_AMOUNT`, `FINAL_COUNT`, `FINAL_AMOUNT`) | Enforcement actions with their agencies, dockets, dispositions, and penalty amounts. | Child records of the evaluation; recoverable by the same join. |
      | Supplemental environmental project fields (`SEP_TYPE`, `SEP_TYPE_DESC`, `EXPENDITURE_AMOUNT`, `SCHEDULED_COMPLETION_DATE`, `ACTUAL_COMPLETION_DATE`, `SEP_DEFAULTED_DATE`) | Supplemental environmental projects tied to enforcement. | Child records of the evaluation; recoverable by the same join. |

- **Considerations**
    - The five evaluation types with their own columns are the five most analytically distinct codes; the remaining ten codes are individually rare and pool into `CE_TOTAL_OTHER` rather than adding ten near-empty column pairs.
    - `U` (undetermined) is deliberately not counted as a found violation, so `CE_EVALS_WITH_VIOL` is a strict "violations discovered" count.
- **Impact**
    - Evaluation types among the 202,501 window evaluations: CEI 111,972 (55.29%), NRR 29,145 (14.39%), FCI 21,519 (10.63%), SNY 4,858 (2.40%), CSE 2,892 (1.43%), and OTHER 32,115 (15.86%).
    - `FOUND_VIOLATION` among the same baseline: Y on 60,041 evaluations (29.65%), N on 140,793 (69.53%), U on 1,667 (0.82%).
    - `NOC_DATE` exists on 5,354 window evaluations (2.64%), so `CE_END_YEAR` and `CE_END_MONTH` are sparse by nature.
    - 15,377 of the 178,762 facility-months with evaluations (8.60%) hold more than one evaluation and use the semicolon joining.

### Decision 7. Balanced Grid and Zero Fill ###
- **Decision**
    - The panel is the full cross of the 87,866 facilities with all 108 months. Months without an evaluation carry 0 in every count and indicator column and empty strings in the descriptive fields, and each `CE_ANY_*` indicator equals 1 exactly when its matching count is positive.
- **Details**
    - A 0 therefore means no evaluation started in that facility-month; it is never a missing value, and the count columns are never empty.
    - The facility attributes of Decision 5 and `FRS_ID` are the only columns filled on evaluation-free months.
- **Considerations**
    - The alternative of keeping only months with evaluations would shrink the file by roughly a factor of fifty but would push the zero-versus-missing distinction onto every user; the explicit grid keeps facility-month time series directly usable for event studies and rate calculations without reconstruction.
- **Impact**
    - 178,762 facility-months (1.88% of the 9,489,528) carry at least one evaluation; the remaining 9,310,766 (98.12%) are zero-filled.
    - The panel carries 202,501 evaluations in total, of which 60,041 (29.65%) discovered violations.