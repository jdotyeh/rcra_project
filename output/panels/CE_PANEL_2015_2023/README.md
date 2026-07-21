# `CE_PANEL_2015_2023` Decision Records #

## Purpose ##
This document records every construction decision behind the three facility-month panels in this folder. `EVAL_PANEL_2015_2023.csv` holds compliance evaluations and is built by `code/modules/03_panels/rcrainfo/03_panel_eval_2015_2023.R`. `ENF_PANEL_2015_2023.csv` holds enforcement actions and is built by `code/modules/03_panels/rcrainfo/04_panel_enf_2015_2023.R`. `VIOL_PANEL_2015_2023.csv` holds determined violations and is built by `code/modules/03_panels/rcrainfo/05_panel_viol_2015_2023.R`. Each panel is also written as an `.rds` twin carrying the exact column types. All three panels are drawn from the same source, `CE_MASTER.csv`, and all three cover the same 108 calendar months, but they are separate files with separate universes and are documented separately below.

Each decision states the outcome that was adopted, the details of how it is implemented, the considerations behind it where alternatives were worth weighing, and the measured impact on the data. Every count is taken from the actual input and output files, and every percentage states the baseline it is measured against. Within each part the decisions appear in the order in which they act on the data, so reading top to bottom follows the construction of the panel from `CE_MASTER.csv` to the final CSV.

## Part 1. The Evaluation Panel ##

### Decision 1. Universe and Unit of Observation ###
- **Decision**
    - The panel is a balanced facility-month panel keyed on `HANDLER_ID`, `YEAR`, and `MONTH`. It covers the 108 calendar months from January 2015 through December 2023, and a facility is included if at least one of its compliance evaluations started in that window. Every included facility carries all 108 months.
- **Details**
    - Each facility-month represents one facility in one calendar month. Months are indexed by `YEAR` (2015-2023) and `MONTH` (1-12).
    - A facility contributes exactly 108 facility-months regardless of how many months hold an evaluation, and months without one are zero-filled per Decision 7.
    - The source is `CE_MASTER.csv`, the compliance monitoring and enforcement master file compiled from RCRAInfo's CM&E module.
- **Considerations**
    - The monthly grain was chosen over an annual one because evaluations are dated events rather than period reports, and a month is fine enough to order events within a year while staying coarse enough that multi-evaluation cells are rare (Decision 6 counts them).
    - The balanced grid means absence of a row never has to be interpreted, because a facility-month with nothing recorded exists in the panel and says so explicitly.
    - Membership is defined by the outcome the panel measures, so a facility that was never evaluated in the window is not in the file at all. The panel therefore describes how often evaluated facilities are evaluated, and it cannot on its own support a statement about the probability that a regulated facility is evaluated.
- **Impact**
    - `CE_MASTER.csv` holds 2,872,361 records covering 306,739 distinct facilities, collapsing to 1,123,893 distinct evaluations (Decision 2).
    - Evaluations starting in 2015-2023 number 202,501 (18.02% of the 1,123,893 distinct evaluations), at 87,866 distinct facilities (28.65% of the 306,739 facilities appearing in `CE_MASTER`).
    - The panel holds 9,489,528 facility-months, exactly 87,866 facilities times 108 months.

### Decision 2. Evaluation Identity and Deduplication ###
- **Decision**
    - One evaluation is one distinct combination of `HANDLER_ID`, `EVAL_ACTIVITY_LOCATION`, `EVAL_IDENTIFIER`, `EVAL_START_DATE`, and `EVAL_AGENCY`, and every count in the panel is a count of these distinct evaluations.
- **Details**
    - `CE_MASTER.csv` repeats the evaluation key across its child records, so the same evaluation can appear on many rows. The panel collapses the file back to one row per evaluation before any counting.
    - `EVAL_IDENTIFIER` alone is not unique across agencies or locations, which is why the full five-column key defines identity. Taking only the facility, activity location, and identifier gives 639,993 triples, of which 135,569 carry more than one start date and the widest carries 1,429.
    - The key was checked for internal consistency. None of the 202,501 window evaluations carries two values of `EVAL_TYPE` or two values of `FOUND_VIOLATION` under one key, so collapsing to the key never has to choose between competing attributes.
- **Considerations**
    - Counting raw rows instead of distinct evaluations would inflate every panel count by whatever follow-on records an evaluation accumulated, and the inflation would correlate with exactly the outcomes a user is likely to study.
- **Impact**
    - The collapse takes 2,872,361 records to 1,123,893 evaluations (39.13% of the row count), so an evaluation spans 2.56 records on average.

### Decision 3. Month Assignment ###
- **Decision**
    - An evaluation belongs to the calendar month of its `EVAL_START_DATE`, which the data dictionary defines as the first day of the inspection or record review regardless of its duration.
- **Details**
    - Evaluations whose start date cannot be parsed cannot be month-assigned and are excluded by construction. In the current data this exclusion is empty, because all 1,123,893 distinct evaluations carry a parseable `EVAL_START_DATE`.
    - Evaluations starting outside 2015-2023 fall outside the panel window and are excluded.
- **Considerations**
    - The start date is the only date carried on every evaluation. The notice-of-compliance date exists on just 2.64 percent of window evaluations (Decision 6 keeps it as an outcome field), so anchoring months anywhere else would leave most evaluations unplaceable.
- **Impact**
    - Excluded for an unparseable date, 0 evaluations (0.00%).
    - Excluded as outside the window, 921,392 evaluations (81.98% of the 1,123,893 distinct evaluations).

### Decision 4. FRS Linkage ###
- **Decision**
    - Every facility-month carries `FRS_ID`, the EPA FRS `REGISTRY_ID`, so the panel can be joined to other EPA programs through a common facility identifier.
- **Details**
    - The link comes from the FRS Program Links file (`data/frs/FRS_PROGRAM_LINKS.csv`), matching the facility's RCRAInfo identifier (`HANDLER_ID`) against `PGM_SYS_ID` on the rows where `PGM_SYS_ACRNM == "RCRAINFO"`.
    - The mapping was verified to be strictly one-to-one on the RCRAINFO rows. The file holds 1,591,859 RCRAINFO rows with 1,591,859 distinct `PGM_SYS_ID` values and zero identifiers mapped to more than one `REGISTRY_ID`, so the join cannot fan out the panel.
    - The reverse direction is not injective. A registry identifier names a physical site, and a site that re-registered under RCRA carries every one of its RCRAInfo identifiers on the same `FRS_ID`. In this panel 649 registry identifiers are shared by two or more facilities, 1,358 facilities in all (1.55 percent of the 87,866), and the widest case is `FRS_ID` 110000618546, carried by eight Pennsylvania facilities. Analyses keyed on `FRS_ID` should expect these clusters rather than assume one facility per registry identifier.
    - `FRS_ID` is empty when no RCRAINFO link exists for the facility.
- **Impact**
    - 87,799 of the 87,866 panel facilities (99.92%) link to an FRS registry identifier. The unmatched remainder is 67 facilities (0.08%) covering 7,236 facility-months (0.08% of the 9,489,528 panel facility-months).

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
    - The attributes are constant within facility in the data except for 18 facilities (0.02% of 87,866) that carry two `HANDLER_ACTIVITY_LOCATION` values across their evaluations, and the most-recent rule fixes those deterministically instead of leaving two competing values.
    - `LAND_TYPE` is blank on 4.51 percent of window evaluation records (9,123 of 202,501), which is why the rule takes the last non-missing value rather than the value on the latest record.
- **Impact**
    - `CE_LAND_TYPE` remains empty for 6,797 facilities (7.74% of 87,866) whose evaluations never record a land type, and the other three attributes are filled for every facility.

### Decision 6. Elements Included from `CE_MASTER.csv` ###
- **Decision**
    - Each facility-month carries four groups of evaluation content, namely descriptive fields for the month's evaluations, count columns by evaluation type, 0/1 indicator columns derived from the counts, and 0/1 context indicators for the month's evaluations. All other `CE_MASTER` elements stay out of the panel.
- **Details**
    - Month-level descriptive fields, empty when the month has no evaluation.

      | Element | Source variable | Description |
      | --- | --- | --- |
      | `CE_EVAL_STATE` | `EVAL_ACTIVITY_LOCATION` | Location of the agency conducting the evaluation, distinct values in start-date order. |
      | `CE_EVAL_AGENCY` | `EVAL_AGENCY` | Agency responsible for conducting the evaluation, distinct values in start-date order. |
      | `CE_EVAL_RESP_PERSON` | `EVAL_RESPONSIBLE_PERSON` | Code of the staff member responsible for the evaluation, distinct values in start-date order. |
      | `CE_EVAL_SUBORG` | `EVAL_SUBORGANIZATION` | Suborganization within the evaluating agency, distinct values in start-date order. |
      | `CE_END_YEAR`, `CE_END_MONTH` | `NOC_DATE` | Year and month the facility was notified that no violations were discovered or that previously discovered violations returned to compliance. |
      | `CE_EVAL_LAST_CHANGE` | `EVAL_LAST_CHANGE` | Most recent change stamp over the month's evaluation records. |

    - Count and indicator columns, 0 on months with no evaluation.

      | Element | Source rule | Description |
      | --- | --- | --- |
      | `CE_ANY_EVAL`, `CE_TOTAL_EVALS` | all evaluations | Evaluations starting in the month. |
      | `CE_ANY_CEI`, `CE_TOTAL_CEI` | `EVAL_TYPE == "CEI"` | Compliance evaluation inspections. |
      | `CE_ANY_NRR`, `CE_TOTAL_NRR` | `EVAL_TYPE == "NRR"` | Non-financial record reviews. |
      | `CE_ANY_FCI`, `CE_TOTAL_FCI` | `EVAL_TYPE == "FCI"` | Focused compliance inspections. |
      | `CE_ANY_FRR`, `CE_TOTAL_FRR` | `EVAL_TYPE == "FRR"` | Financial record reviews. |
      | `CE_ANY_FSD`, `CE_TOTAL_FSD` | `EVAL_TYPE == "FSD"` | Facility self disclosures. |
      | `CE_ANY_OTHER`, `CE_TOTAL_OTHER` | every other `EVAL_TYPE` | The remaining evaluation types, which are SNY, SNN, FUI, CSE, CDI, CAV, OAM, CAC, GME, and NIR. |
      | `CE_ANY_VIOL`, `CE_EVALS_WITH_VIOL` | `FOUND_VIOLATION == "1"` | Evaluations that discovered violations at the facility. `CE_MASTER` codes the flag "1", "0", and "U", and "0" and "U" (undetermined) do not count. |

    - Context indicators, 1 when any evaluation in the month carries the flag and 0 otherwise.

      | Element | Source variable | Description |
      | --- | --- | --- |
      | `CE_ANY_CITIZEN_COMPLAINT` | `CITIZEN_COMPLAINT` | The evaluation was prompted by a citizen complaint. |
      | `CE_ANY_MULTIMEDIA_INSPECTION` | `MULTIMEDIA_INSPECTION` | The evaluation was part of a multimedia inspection. |
      | `CE_ANY_SAMPLING` | `SAMPLING` | Samples were taken during the evaluation. |
      | `CE_ANY_NOT_SUBTITLE_C` | `NOT_SUBTITLE_C` | The evaluation addressed something other than Subtitle C requirements. |

    - Months holding more than one evaluation join the multi-valued descriptive fields with semicolons in evaluation start-date order, and the i-th `CE_END_YEAR` entry pairs with the i-th `CE_END_MONTH` entry.
    - Elements of `CE_MASTER.csv` not included in the panel, grouped, with the rationale for exclusion.

      | Elements | Description | Rationale |
      | --- | --- | --- |
      | `HANDLER_NAME` | Facility legal name. | The facility is already keyed by `HANDLER_ID` and `FRS_ID`. |
      | Child-record keys (`VIOL_SEQ`, `REQUEST_SEQ`, `CITATION_SEQ`, `CAFO_SEQ`, `SEP_SEQ`, `ENF_IDENTIFIER`) | Sequence numbers and identifiers of the records that repeat the evaluation key. | Record machinery, not facility-month content. |
      | Evaluation detail (`EVAL_TYPE_DESC`, `FOCUS_AREA`, `FOCUS_AREA_DESC`) | Type descriptions and focus areas of the individual evaluation. | Evaluation-level detail beneath the month grain, recoverable by joining the evaluation key back to `CE_MASTER.csv`. |
      | Information-request fields (`DATE_OF_REQUEST`, `DATE_RESPONSE_RECEIVED`, `REQUEST_AGENCY`, `REQUEST_ACTIVITY_LOCATION`) | RCRA 3007 information requests attached to the evaluation. | Child records of the evaluation, recoverable by the same join. |
      | Violation fields (`VIOL_ACTIVITY_LOCATION`, `VIOL_TYPE`, `VIOL_TYPE_OWNER`, `VIOL_SHORT_DESC`, `DETERMINED_DATE`, `VIOL_DETERMINED_BY_AGENCY`, `RESPONSIBLE_AGENCY`, `SCHEDULED_COMPLIANCE_DATE`, `ACTUAL_RTC_DATE`, `RTC_QUALIFIER`, `CITATION`, `CITATION_OWNER`, `CITATION_TYPE`, `FORMER_CITATION`, `VIOL_LAST_CHANGE`) | Determined violations with their citations, compliance schedules, and return-to-compliance dates. | Carried by the companion violation panel documented in Part 3, on the date the violation was determined rather than on the evaluation's month. The facility-month here keeps the evaluation-level `FOUND_VIOLATION` signal. |
      | Enforcement fields (`ENF_ACTIVITY_LOCATION`, `ENF_TYPE`, `ENF_TYPE_DESC`, `ENF_ACTION_DATE`, `ENF_AGENCY`, `DOCKET_NUMBER`, `ATTORNEY`, `ENF_RESPONSIBLE_PERSON`, `ENF_SUBORGANIZATION`, `CA_COMPONENT`, `FA_REQUIREMENT`, appeal and disposition fields, `RESPONDENT_NAME`, `LEAD_AGENCY`, `ENF_LAST_CHANGE`, `PROPOSED_AMOUNT`, `FINAL_MONETARY_AMOUNT`, `PAID_AMOUNT`, `FINAL_COUNT`, `FINAL_AMOUNT`) | Enforcement actions with their agencies, dockets, dispositions, and penalty amounts. | Carried by the companion enforcement panel documented in Part 2, on its own action date rather than on the evaluation's month. |
      | Supplemental environmental project fields (`SEP_TYPE`, `SEP_TYPE_DESC`, `EXPENDITURE_AMOUNT`, `SCHEDULED_COMPLETION_DATE`, `ACTUAL_COMPLETION_DATE`, `SEP_DEFAULTED_DATE`) | Supplemental environmental projects tied to enforcement. | Child records of the enforcement action, recoverable by joining the enforcement key back to `CE_MASTER.csv`. |

- **Considerations**
    - The five evaluation types with their own columns are the five most common codes in the window, and the remaining ten codes are individually rare and pool into `CE_TOTAL_OTHER` rather than adding ten near-empty column pairs.
    - `U` (undetermined) is deliberately not counted as a found violation, so `CE_EVALS_WITH_VIOL` is a strict count of evaluations that discovered violations.
- **Impact**
    - Evaluation types among the 202,501 window evaluations are CEI with 111,972 (55.29%), NRR with 29,145 (14.39%), FCI with 21,519 (10.63%), FRR with 9,087 (4.49%), FSD with 6,473 (3.20%), and OTHER with 24,305 (12.00%).
    - `FOUND_VIOLATION` among the same baseline is "1" on 60,041 evaluations (29.65%), "0" on 140,793 (69.53%), and "U" on 1,667 (0.82%).
    - Blankness of the descriptive fields, measured against the 178,762 facility-months that hold at least one evaluation, is 0 for `CE_EVAL_STATE`, `CE_EVAL_AGENCY`, and `CE_EVAL_LAST_CHANGE`, 22,317 (12.48%) for `CE_EVAL_RESP_PERSON`, 60,727 (33.97%) for `CE_EVAL_SUBORG`, and 173,623 (97.13%) for `CE_END_YEAR` and `CE_END_MONTH`. `NOC_DATE` exists on only 5,354 window evaluations (2.64%), so the two end-date columns are sparse by nature.
    - The context indicators mark few months against the same baseline, with citizen complaint on 4,904 (2.74%), multimedia inspection on 4,695 (2.63%), sampling on 467 (0.26%), and not-Subtitle-C on 242 (0.14%).
    - 15,377 of the 178,762 facility-months with evaluations (8.60%) hold more than one evaluation and use the semicolon joining, and the largest is 63 evaluations in one month.

### Decision 7. Balanced Grid and Zero Fill ###
- **Decision**
    - The panel is the full cross of the 87,866 facilities with all 108 months. Months without an evaluation carry 0 in every count and indicator column and empty strings in the descriptive fields, and each `CE_ANY_*` indicator equals 1 exactly when its matching count is positive.
- **Details**
    - A 0 therefore means no evaluation started in that facility-month. It is never a missing value, and the count columns are never empty.
    - The facility attributes of Decision 5 and `FRS_ID` are the only columns filled on evaluation-free months.
- **Considerations**
    - The alternative of keeping only months with evaluations would shrink the file by roughly a factor of fifty but would push the zero-versus-missing distinction onto every user. The explicit grid keeps facility-month time series directly usable for event studies and rate calculations without reconstruction.
    - The grid does not know when a facility began or ceased to be regulated, so the zeros before a facility's first evaluation and after its last are structural rather than observed. Analyses that need an at-risk window have to build one from the notification history in `HD_MASTER.csv`.
- **Impact**
    - 178,762 facility-months (1.88% of the 9,489,528) carry at least one evaluation, and the remaining 9,310,766 (98.12%) are zero-filled.
    - The panel carries 202,501 evaluations in total, of which 60,041 (29.65%) discovered violations.

## Part 2. The Enforcement Panel ##

### Decision 8. Universe and Unit of Observation ###
- **Decision**
    - The panel is a balanced facility-month panel keyed on `HANDLER_ID`, `YEAR`, and `MONTH`. It covers the same 108 calendar months from January 2015 through December 2023, and a facility is included if at least one of its enforcement actions is dated in that window. Every included facility carries all 108 months.
- **Details**
    - The unit, the month index, and the zero-fill convention match the evaluation panel exactly, so the two files can be joined on `HANDLER_ID`, `YEAR`, and `MONTH`.
    - The two universes are not the same. The enforcement panel is a near subset of the evaluation panel, but 340 of its facilities receive an action in the window without an evaluation in the window, so a join of the two files has to state which side it keeps.
- **Considerations**
    - The universes were left separate rather than forced onto the evaluation panel's facility list, because that would have dropped the 340 enforcement-only facilities and would have given 56,034 facilities a full enforcement grid of zeros they never had an action to fill.
    - As with the evaluation panel, membership is defined by the outcome the panel measures, so the file describes the intensity of enforcement at facilities that were subject to enforcement and not its incidence across the regulated universe.
- **Impact**
    - `CE_MASTER.csv` holds 1,928,016 enforcement records covering 131,600 distinct facilities, collapsing to 365,899 distinct enforcement actions (Decision 9).
    - Actions dated 2015-2023 number 56,098 (15.33% of the 365,899 distinct actions), at 32,172 distinct facilities (24.45% of the 131,600 facilities carrying any action).
    - The panel holds 3,474,576 facility-months, exactly 32,172 facilities times 108 months.
    - 31,832 of the 32,172 facilities (98.94%) also appear in the evaluation panel.

### Decision 9. Enforcement Action Identity and Deduplication ###
- **Decision**
    - One enforcement action is one distinct combination of `HANDLER_ID`, `ENF_ACTIVITY_LOCATION`, `ENF_IDENTIFIER`, `ENF_ACTION_DATE`, and `ENF_AGENCY`, and every count in the panel is a count of these distinct actions.
- **Details**
    - `CE_MASTER.csv` repeats the enforcement key across the evaluation, violation, citation, and supplemental project rows it belongs to, so one action can appear on many rows. The panel collapses the file back to one row per action before any counting.
    - `ENF_IDENTIFIER` is a sequence within a facility and activity location rather than an identifier of one action, so it cannot define identity on its own. The facility NJD002385730 with `ENF_ACTIVITY_LOCATION` NJ and `ENF_IDENTIFIER` 001 carries 176 distinct action dates running from 1984-03-15 to 2023-08-28, and 46,496 of the 247,819 facility, location, and identifier triples in the file carry more than one action date.
    - The key was checked for internal consistency. None of the 56,098 window actions carries two values of `ENF_TYPE` or two values of `DOCKET_NUMBER` under one key, so collapsing to the key never has to choose between competing attributes.
- **Considerations**
    - Counting raw rows instead of distinct actions would inflate every panel count by the number of evaluations, violations, and citations an action happened to touch, which is precisely the severity signal a user would want to study separately.
- **Impact**
    - The collapse takes 1,928,016 enforcement records to 365,899 actions (18.98% of the row count), so an action spans 5.27 records on average.

### Decision 10. Month Assignment ###
- **Decision**
    - An enforcement action belongs to the calendar month of its `ENF_ACTION_DATE`, the date the action was issued.
- **Details**
    - `ENF_ACTION_DATE` is populated and parseable on every enforcement record in the data, so no action is dropped for a missing or malformed date.
    - Actions dated outside 2015-2023 fall outside the panel window and are excluded.
    - The disposition of an action describes how an action issued in the month was later closed, so `CE_DISP_DATE` can fall in a later month than the row that carries it.
- **Impact**
    - Excluded for an unparseable or blank date, 0 actions (0.00%).
    - Excluded as outside the window, 309,801 actions (84.67% of the 365,899 distinct actions).

### Decision 11. FRS Linkage ###
- **Decision**
    - Every facility-month carries `FRS_ID` on the same rule as Decision 4.
- **Details**
    - The link, the source file, and the verification of one-to-one mapping are identical to Decision 4 and are not repeated here.
    - The same site clustering applies. This panel holds 158 registry identifiers shared by two or more facilities, covering 323 of its 32,172 facilities (1.00 percent).
- **Impact**
    - 32,163 of the 32,172 panel facilities (99.97%) link to an FRS registry identifier. The unmatched remainder is 9 facilities (0.03%) covering 972 facility-months (0.03% of the 3,474,576 panel facility-months).

### Decision 12. Facility Attributes ###
- **Decision**
    - The same four facility-level attributes as Decision 5 are taken from the facility snapshot columns riding on the enforcement records, fixed at one value per facility, and repeated across all 108 of its months.
- **Details**
    - The value used is the value on the facility's most recent action for the three state and region attributes, and the last non-missing value for `CE_LAND_TYPE`.
    - The attributes are drawn from the enforcement records of this panel rather than copied from the evaluation panel, so a facility present in both files can in principle carry a different snapshot in each.
- **Considerations**
    - The attributes are constant within facility in the data except for 3 facilities (0.01% of 32,172) that carry two `HANDLER_ACTIVITY_LOCATION` values across their actions, and the most-recent rule fixes those deterministically.
    - `LAND_TYPE` is blank on 4.88 percent of window enforcement actions (2,738 of 56,098), which is why the rule takes the last non-missing value.
- **Impact**
    - `CE_LAND_TYPE` remains empty for 1,821 facilities (5.66% of 32,172), and the other three attributes are filled for every facility.
    - `CE_ACTIVITY_STATE` differs from `CE_LOCATION_STATE` for 22 facilities (0.07%).

### Decision 13. Elements Included from `CE_MASTER.csv` ###
- **Decision**
    - Each facility-month carries three groups of enforcement content, namely descriptive fields for the month's actions, count columns by issuing agency, and 0/1 indicator columns. All other `CE_MASTER` elements stay out of the panel.
- **Details**
    - Month-level descriptive fields, empty when the month has no action. Months holding more than one action join the multi-valued fields with semicolons in action-date order.

      | Element | Source variable | Description |
      | --- | --- | --- |
      | `CE_ENF_STATE` | `ENF_ACTIVITY_LOCATION` | The state whose agency issued the action. |
      | `CE_ENF_TYPE` | `ENF_TYPE` | The month's distinct nationally-defined type codes after the recode described in Decision 14, sorted. |
      | `CE_ENF_TYPE_UNDEFINED` | `ENF_TYPE` | The month's distinct codes that are not nationally defined, sorted, carried exactly as the states recorded them and unaffected by the recode. |
      | `CE_ENF_TYPE_DESC` | `ENF_TYPE_DESC` | The month's distinct type descriptions. A defined code takes its name from the national reference table and a state-specific code takes the crosswalk's revised reading of what the state wrote. |
      | `CE_ENF_CATEGORY` | `ENF_TYPE` | The month's distinct proposed categories from the 900 block, sorted. Empty when no action in the month carries one. |
      | `CE_ENF_TYPE_NUM` | `ENF_TYPE` | Count of distinct type codes in the month as they were recorded, defined and undefined together, so the recode does not change it. |
      | `CE_DOCKET` | `DOCKET_NUMBER` | Docket numbers of the month's actions. |
      | `CE_ATTORNEY` | `ATTORNEY` | Codes of the attorneys assigned to the month's actions. |
      | `CE_ENF_RESP_PERSON` | `ENF_RESPONSIBLE_PERSON` | Codes of the staff members responsible for the month's actions. |
      | `CE_ENF_SUBORG` | `ENF_SUBORGANIZATION` | Suborganization codes, each prefixed with its own enforcement state as STATE-SUBORG, for example IL-CD. |
      | `CE_DISP_STATUS` | `DISPOSITION_STATUS` | Distinct disposition codes of the month's actions. |
      | `CE_DISP_DATE` | `DISPOSITION_STATUS_DATE` | Distinct disposition dates. Status and date are deduplicated independently and are not positionally paired. |
      | `CE_CAFO_RESPONDENT` | `RESPONDENT_NAME` | Respondent named on a consent agreement or final order. |
      | `CE_CAFO_LEAD_AGENCY` | `LEAD_AGENCY` | Lead agency on a consent agreement or final order. |
      | `CE_ENF_LAST_CHANGE` | `ENF_LAST_CHANGE` | Most recent change stamp over the month's enforcement records. |

    - Count and indicator columns, 0 on months with no action.

      | Element | Source rule | Description |
      | --- | --- | --- |
      | `CE_ANY_ENF`, `CE_TOTAL_ENF` | all actions | Enforcement actions issued in the month. |
      | `CE_ANY_STATE_ENF`, `CE_TOTAL_STATE_ENF` | `ENF_AGENCY == "S"` | Actions issued by a state agency. |
      | `CE_ANY_FED_ENF`, `CE_TOTAL_FED_ENF` | `ENF_AGENCY == "E"` | Actions issued by EPA. |
      | `CE_ENF_FORMAL` | recoded type in 210 through 865, or a 999 pair the crosswalk classifies as formal | Any action in the month is a formal action. |
      | `CE_ENF_INFORMAL` | recoded type in 110, 120, 130, 140, or a 999 pair the crosswalk classifies as informal | Any action in the month is an informal action. |
      | `CE_ANY_CA_COMPONENT` | `CA_COMPONENT == "1"` | Any action in the month carries a corrective-action component. |
      | `CE_ANY_FA_REQUIREMENT` | `FA_REQUIREMENT == "1"` | Any action in the month carries a financial-assurance requirement. |

    - Elements of `CE_MASTER.csv` not included in the panel, grouped, with the rationale for exclusion.

      | Elements | Description | Rationale |
      | --- | --- | --- |
      | `HANDLER_NAME` | Facility legal name. | The facility is already keyed by `HANDLER_ID` and `FRS_ID`. |
      | Appeal fields (`APPEAL_INITIATED_DATE`, `APPEAL_RESOLVED_DATE`, `DISPOSITION_STATUS_DESC`) | Appeal timeline and the long form of the disposition code. | Action-level detail beneath the month grain, recoverable by joining the enforcement key back to `CE_MASTER.csv`. |
      | Penalty fields (`PROPOSED_AMOUNT`, `FINAL_MONETARY_AMOUNT`, `PAID_AMOUNT`, `FINAL_COUNT`, `FINAL_AMOUNT`) | Proposed, final, and paid penalty amounts and the counts on a consent agreement or final order. | Populated on a small minority of actions and at a rate that differs by issuing agency, so they are left out rather than delivered as a column that is empty on most rows. See the considerations below. |
      | Evaluation, violation, citation, information-request, and supplemental project fields | The records the enforcement key rides on in `CE_MASTER.csv`. | Documented in Part 1 and Part 3 or left to a join on the enforcement key. |

- **Considerations**
    - Enforcement responsible agency is "S" or "E" for every action in the window, so the state and federal split is exhaustive. Any other agency code, if it ever appears, would count toward neither.
    - The defined and undefined split exists because enforcement type codes are only partly national. The 37 nationally defined codes come from the RCRAInfo CME enforcement-type reference, and everything else is a state-specific code. A user comparing enforcement severity across states has to reckon with the undefined side, because the same numeric code can carry different meanings in different states. Code 312 is described as STATE AG SETTLED OUT OF COURT in CT and MA, DE NOTICE OF ADMIN PENALTY / ORDER in DE, DEP SHORT FORM CONSENT ORDER in FL, Settlement Agreement Sent to AGO in MO, and CONSENT ORDER AND AGREEMENT in PA.
    - `CE_ANY_FA_REQUIREMENT` is delivered for completeness but is effectively empty, and it should not be used as a measure of financial-assurance activity. `FA_REQUIREMENT` is coded "1" on 74 of the 1,928,016 enforcement records in `CE_MASTER`, which is 13 distinct actions in the whole file, and it is blank on 469,817 records (24.37%) against 2,822 (0.15%) for the companion flag `CA_COMPONENT`. The asymmetry suggests the source field is incompletely populated rather than genuinely negative.
    - Federal counts in 2022 are dominated by multi-site cases. Enforcement type 380 is a multi-site super consent agreement, one legal case covering many sites, and the panel records it once at each site. The single date 2022-09-28 carries 849 actions of that type at 849 distinct facilities, and type 380 totals 1,527 actions in 2022 against 46 or fewer in every year of the window other than 2021, which holds 167. A user counting federal actions over time should separate this type.
- **Impact**
    - The panel carries 56,098 actions, of which 50,242 (89.56%) were issued by a state agency and 5,856 (10.44%) by EPA.
    - Enforcement type codes on the window actions split into 40,950 carrying a nationally defined code (73.00%) and 15,148 carrying a state-specific code (27.00%), the latter spread over 77 distinct code values.
    - Blankness of the descriptive fields, measured against the 51,962 facility-months that hold at least one action, is 0 for `CE_ENF_STATE` and `CE_ENF_LAST_CHANGE`, 4,992 (9.61%) for `CE_ENF_TYPE`, 4,117 (7.92%) for `CE_ENF_TYPE_DESC`, 37,911 (72.96%) for `CE_ENF_TYPE_UNDEFINED`, 9,190 (17.69%) for `CE_ENF_RESP_PERSON`, 19,548 (37.62%) for `CE_ENF_SUBORG`, 44,784 (86.19%) for `CE_DOCKET`, 45,100 (86.79%) for `CE_DISP_STATUS`, 45,102 (86.80%) for `CE_DISP_DATE`, 49,680 (95.61%) for `CE_ATTORNEY`, and 50,177 (96.56%) for `CE_CAFO_RESPONDENT` and `CE_CAFO_LEAD_AGENCY`.
    - `CE_ENF_TYPE_NUM` is 1 on 48,915 active months (94.14%), 2 on 2,890 (5.56%), 3 on 152 (0.29%), 4 on 4, and 5 on 1.
    - `CE_ANY_CA_COMPONENT` is 1 on 2,037 active months (3.92%) and `CE_ANY_FA_REQUIREMENT` on 4 (0.01%).
    - 3,558 of the 51,962 facility-months with actions (6.85%) hold more than one action and use the semicolon joining, and the largest is 22 actions in one month.

### Decision 14. Enforcement Type Recode and the Formal and Informal Split ###
- **Decision**
    - Each state-specific enforcement type code is matched to the nationally defined code its recorded description most closely describes, and `CE_ENF_TYPE` carries the matched code alongside the untouched original in `CE_ENF_TYPE_UNDEFINED`. A pair that no defined code covers is matched to 999 and stays out of `CE_ENF_TYPE`. `CE_ENF_TYPE_DESC` carries the reference name for a defined code and the crosswalk's revised reading of the state's wording for a state-specific one. `CE_ENF_FORMAL` and `CE_ENF_INFORMAL` classify the month from the recoded codes, and `CE_ENF_CATEGORY` carries the proposed 900-block category where the crosswalk assigns one.
- **Details**
    - The matching decisions live in two reference files rather than in the panel script, so the script reads them and neither list is repeated in code. `resources/CME-Enforcement-Type.md` reproduces the RCRAInfo Nationally-Defined Values page for Enforcement Type and supplies the 37 defined codes with their names. `resources/CME-Enforcement-Type-Crosswalk.md` records, for every state-specific code and description pair that appears in `CE_MASTER`, the defined code it was matched to and the reasoning behind the match.
    - `CE_ENF_TYPE_DESC` delivers the crosswalk's revised reading of each state description rather than the raw string, so `PROPOSED CAO` reads `Proposed Corrective Action Order` and a Florida `DEP MEETING` reads `FL DEP Meeting`. The revised reading is title-cased, has its abbreviations expanded, and carries no comma, which matters because the field joins several descriptions with semicolons and a comma inside one of them would make the field ambiguous to anything that splits on it. The state's raw string is the crosswalk's join key and stays recoverable by taking `CE_ENF_TYPE_UNDEFINED` back to the reference file.
    - Two national names do carry a comma, `Initial Monitoring, Analysis, Test Order` and `Final Monitoring, Analysis, Test Order` under codes 230 and 330, which `CE_MASTER` records as `INITIAL MONITORING,ANALYSIS,TEST ORDER` and `FINAL MONITORING,ANALYSIS,TEST ORDER`. They are reproduced as EPA writes them rather than reworded. The comma does not disturb the CSV, because `write_csv()` quotes any value that holds one, so the file parses back to the same 3,474,576 rows and 33 columns and the value returns intact. Sixteen values in the panel carry a comma, one in `CE_ENF_TYPE_DESC`, one each in `CE_DOCKET` and `CE_ATTORNEY`, and thirteen in `CE_CAFO_RESPONDENT`, and all sixteen are quoted. No panel value contains a double quote or a line break, so the file's physical line count equals its row count plus the header. What a reader must not do is split a row on commas without honouring the quotes, and what it must not do inside a multi-valued field is split on anything other than the semicolon.
    - The crosswalk is keyed on the code and the description together, not on the code alone, because one state code carries descriptions that belong to different defined codes. Code 121 recodes to 120 when its description is VIOLATION NOTICE (VN) in IL, MI, OH, and WI, and to 140 when its description is VIOLATION LETTER - INTENT TO SUBMIT TO DEQ ENF in MT. Code 315 recodes to 310 when its description is DEP CONSENT ORDER in FL and to 305 when its description is an expedited enforcement action offer in WA.
    - A pair whose description is missing is matched to 999 regardless of its code band, because the number alone is not evidence of what the state meant by it. This is the largest single source of 999, covering 5,700 of the 7,199 window actions that stay unmatched (79.18%). The remaining unmatched actions are well described but have no national analogue, such as the internal referrals to an enforcement screening committee recorded under code 141 in TX.
    - The formal and informal split follows the code band, where 110, 120, 130, and 140 are the notification codes and every defined code from 210 upward is an order, a court filing, or a referral. It is deliberately not taken from the "Formal Action" column of the reference table, which marks the narrower set of actions that count as addressing a significant non-complier and therefore flags several unambiguously formal codes 0, including the criminal codes 710 through 740.
    - A pair matched to 999 has no code to take a class from, so the crosswalk records the class on the nine pairs whose own description settles it, and the panel reads it from there. Six are formal because the description names an order or a court filing outright, namely `STATE LEVEL ADMINISTRATIVE ORDER` under 123 and 124, `ADMINISTRATIVE ORDER` under 205, `INJUNCTIVE RELIEF` under 263, `PETITION FOR CONTEMPT` under 512, and the revocation order under 211. Three are informal because the description says so, namely `INFORMAL ACTIONS` under 101, `INFORMAL ENFORCEMENT - OTHER` under 115, and the section 3007 information request letter under 115. Every other 999 pair is left unclassified, which states that the record does not establish the class rather than that the action is neither.
    - The 37 nationally-defined codes are listed below with the class each one carries and how the window's actions reach it. "Recorded" counts the actions a state already filed under the code; "added" counts the actions the recode brings to it from a state-specific code. A code with 0 in both columns is defined nationally but unused in the 2015-2023 window.

      | Code | Name | Class | Recorded | Added |
      | ---- | ---- | ----- | -------- | ----- |
      | 110 | Verbal Informal | informal | 3,111 | 519 |
      | 120 | Written Informal | informal | 27,562 | 5,659 |
      | 130 | Notice of Determination | informal | 390 | 0 |
      | 140 | Letter of Intent to Initiate Enforcement Action | informal | 1,269 | 193 |
      | 210 | Initial 3008(a) Compliance | formal | 1,966 | 770 |
      | 220 | Initial Imminent and Substantial Endangerment Order | formal | 78 | 0 |
      | 230 | Initial Monitoring, Analysis, Test Order | formal | 0 | 0 |
      | 240 | Initial 3008(h) I.S. CA Order | formal | 4 | 60 |
      | 250 | Field Citation | formal | 2 | 119 |
      | 305 | 3008(a) Expedited Settlement Agreement | formal | 63 | 66 |
      | 310 | Final 3008(a) Compliance Order | formal | 3,646 | 517 |
      | 320 | Final Imminent Hazard Order | formal | 21 | 0 |
      | 330 | Final Monitoring, Analysis, Test Order | formal | 1 | 0 |
      | 340 | Final 3008(h) I.S. CA Order | formal | 9 | 1 |
      | 380 | Multi Site Super CA/FO | formal | 1,811 | 0 |
      | 385 | Single Site Super CA/FO | formal | 511 | 7 |
      | 410 | Referral to Attorney General | formal | 68 | 0 |
      | 420 | Referral to Department of Justice | formal | 6 | 0 |
      | 425 | Referral to DOJ to Collect Penalties | formal | 0 | 0 |
      | 430 | Referral to District Attorney/City Attorney/County Attorney/State Attorney | formal | 0 | 0 |
      | 510 | Initial Civil/Judicial Action for Compliance and/or Monetary Penalty | formal | 136 | 19 |
      | 520 | Initial Civil Action for Imminent and Substantial Endangerment | formal | 0 | 0 |
      | 530 | Initial Civil/Judicial Action for Corrective Action | formal | 0 | 0 |
      | 610 | Final Civil/Judicial Action for Compliance and/or Monetary Penalty | formal | 213 | 11 |
      | 620 | Final Civil/Judicial Action for Imminent and Substantial Endangerment | formal | 0 | 0 |
      | 630 | Final Civil/Judicial Action for Interim Corrective Action | formal | 0 | 0 |
      | 710 | Referral to Criminal | formal | 1 | 0 |
      | 720 | Criminal Indictment | formal | 1 | 0 |
      | 730 | Criminal Conviction | formal | 4 | 0 |
      | 740 | Criminal Acquittal | formal | 0 | 0 |
      | 810 | State to EPA Administrative Referral | formal | 20 | 0 |
      | 820 | EPA to State Administrative Referral | formal | 26 | 0 |
      | 830 | RCRA to CERCLA Administrative Referral | formal | 15 | 2 |
      | 840 | EPA Regions to EPA HQ Administrative Referral | formal | 4 | 0 |
      | 850 | Administrative Referrals to Other RCRA Programs | formal | 1 | 0 |
      | 860 | Administrative Referrals to Other Programs | formal | 11 | 0 |
      | 865 | Referral to U.S. Treasury | formal | 0 | 6 |

    - The proposed categories occupy the 900 block, chosen because no state code observed in `CE_MASTER` reaches 900, so a category can never collide with a recorded value. They exist because a single defined code collapses instruments a user may want apart, most of all 120 Written Informal, which absorbs the warning letters, the notices of violation, the notices of noncompliance, and the compliance advisories alike. A category never replaces the matched code; it rides alongside it in `CE_ENF_CATEGORY`. "Matches to" names the defined codes the category's pairs resolve to, and 999 there means the category is carrying records that no defined code covers at all.

      | Category | Name | Matches to | State codes | Window actions |
      | -------- | ---- | ---------- | ----------- | -------------- |
      | 901 | Warning Letter | 120 | 4 | 1,151 |
      | 902 | Notice of Violation | 120 | 4 | 992 |
      | 903 | Notice of Noncompliance | 120, 999 | 4 | 1,630 |
      | 904 | Compliance Advisory or Assistance Letter | 120 | 3 | 1,345 |
      | 905 | Enforcement Meeting or Conference | 110, 999 | 8 | 527 |
      | 906 | Internal Referral to Enforcement | 999 | 5 | 601 |
      | 907 | Proposed or Draft Order | 210, 240 | 4 | 581 |
      | 908 | Case Closeout or Action Withdrawn | 999 | 9 | 486 |
      | 909 | Administrative Workflow Milestone | 999 | 3 | 268 |
      | 910 | Appeal, Hearing, or Remand | 999 | 3 | 23 |
      | 911 | Stipulated Penalty Demand | 999 | 3 | 9 |
      | 912 | Notice of Deficiency | 120 | 1 | 17 |

    - Five of the categories, 906 and 908 through 911, land entirely on 999. They are the clearest gain from the block, because they separate internal referrals, case closeouts, workflow stamps, appeals, and stipulated penalty demands from the mass of records that are unclassifiable only because they carry no description.

- **Considerations**
    - The recode changes what `CE_ENF_TYPE` means. Before it, the field held only codes the states had already recorded as national. After it, the field mixes those with codes assigned here by reading a description, so a user who needs the states' own coding should read `CE_ENF_TYPE_UNDEFINED`, which is preserved for exactly that purpose.
    - `CE_ENF_TYPE_NUM` still counts the codes as they were recorded, so it is unaffected by the recode and does not agree with the number of values in `CE_ENF_TYPE` on months where a state-specific code recodes onto a defined code already present.
    - A month can set both indicators, since 393 active months (0.76%) hold a formal and an informal action together, and sets neither when no action in it is classified.
    - The crosswalk covers every state-specific code and description pair in `CE_MASTER`, and the script reports a count if a pair ever appears that the file does not list. Such a pair falls to 999 rather than stopping the build, so the report is the signal that the reference file needs the pair added.
- **Impact**
    - Of the 15,148 window actions carrying a state-specific code, 7,949 (52.48%) recode onto a defined code and 7,199 (47.52%) stay at 999. The recode targets are concentrated, with 5,659 going to 120, 770 to 210, 519 to 110, and 517 to 310.
    - Across all 56,098 window actions the recode leaves 38,703 informal (68.99%), 10,196 formal (18.18%), and 7,199 unmatched (12.83%).
    - Blankness of `CE_ENF_TYPE` on active months falls from 12,392 (23.85%) before the recode to 4,992 (9.61%) after it. Of the 14,051 active months carrying a state-specific code, 9,059 (64.47%) now also carry a defined code.
    - `CE_ENF_TYPE_DESC` is blank on 4,117 active months (7.92%), which is lower than the blankness of `CE_ENF_TYPE` because the reference name fills the 493 window actions that carry a defined code with no description of their own.
    - `CE_ENF_INFORMAL` is 1 on 37,820 active months (72.78%) and `CE_ENF_FORMAL` on 9,607 (18.49%), leaving 4,928 (9.48%) with neither. The nine classified 999 pairs are what separates the two indicators from the recode, setting a class on 64 active months that carry no defined code at all.
    - `CE_ENF_CATEGORY` is populated on 7,410 active months (14.26%) and covers 7,630 window actions (13.60% of the 56,098). The categories that fall entirely on 999 account for 1,387 of those actions, namely 601 internal referrals, 486 case closeouts, 268 workflow milestones, 23 appeals, and 9 stipulated penalty demands, none of which would be distinguishable from an undescribed record without the block.
    - Within the 5,659 window actions the recode sends to 120, the categories separate 1,629 notices of noncompliance, 1,345 compliance advisories, 1,151 warning letters, 992 notices of violation, and 17 notices of deficiency, leaving 525 that no category covers. That separation is the distinction the single defined code erases.

### Decision 15. Balanced Grid and Zero Fill ###
- **Decision**
    - The panel is the full cross of the 32,172 facilities with all 108 months, on the same zero-fill convention as Decision 7.
- **Impact**
    - 51,962 facility-months (1.50% of the 3,474,576) carry at least one enforcement action, and the remaining 3,422,614 (98.50%) are zero-filled.

## Part 3. The Violation Panel ##

### Decision 16. Universe and Unit of Observation ###
- **Decision**
    - The panel is a balanced facility-month panel keyed on `HANDLER_ID`, `YEAR`, and `MONTH`. It covers the same 108 calendar months from January 2015 through December 2023, and a facility is included if at least one of its violations was determined in that window. Every included facility carries all 108 months.
- **Details**
    - The unit, the month index, and the zero-fill convention match the other two panels exactly, so all three files can be joined on `HANDLER_ID`, `YEAR`, and `MONTH`.
    - The source is `CE_MASTER.csv`, the same compliance monitoring and enforcement master file behind the evaluation and enforcement panels.
- **Considerations**
    - A determined violation is a dated finding rather than a period report, so the monthly grain used by the other two panels carries over without change.
    - As with the other two panels, membership is defined by the outcome the panel measures, so the file describes how many violations are found at facilities that had at least one violation and not the incidence of violations across the regulated universe.
    - The universe is close to but not the same as the evaluation panel's. Nearly every facility with a window violation also has a window evaluation, but four facilities carry a determined violation in the window without either a window evaluation or a window enforcement action, so a join across the three files has to state which side it keeps.
- **Impact**
    - `CE_MASTER.csv` holds 2,872,361 records covering 306,739 distinct facilities. Of these, 2,126,109 records carry a violation, covering 147,048 distinct facilities and collapsing to 1,031,959 distinct violations (Decision 17).
    - Violations determined in 2015-2023 number 206,708 (20.03% of the 1,031,959 distinct violations), at 38,618 distinct facilities (26.26% of the 147,048 facilities carrying any violation).
    - The panel holds 4,170,744 facility-months, exactly 38,618 facilities times 108 months.
    - Of the 38,618 panel facilities, 38,594 (99.94%) also appear in the evaluation panel and 31,303 (81.06%) also appear in the enforcement panel, and 4 appear in neither.

### Decision 17. Violation Identity and Deduplication ###
- **Decision**
    - One violation is one distinct combination of `HANDLER_ID`, `VIOL_ACTIVITY_LOCATION`, `VIOL_SEQ`, and `VIOL_DETERMINED_BY_AGENCY`, the key the CM&E structure chart uses to link a citation row back to the violation it belongs to, and every count in the panel is a count of these distinct violations.
- **Details**
    - `CE_MASTER.csv` repeats the violation key across the evaluations that found the violation, the enforcement actions that address it, and its own citation rows, so one violation can appear on many rows. The panel collapses the file back to one row per violation before any counting.
    - `VIOL_SEQ` is a sequence within a facility and activity location rather than an identifier of one violation, so it cannot define identity on its own. Of the 1,015,608 facility, activity location, and sequence triples in the file, 16,351 carry more than one determining agency, which is why the agency belongs in the key, and 873 of those triples fall inside the window. At AZD980735179 the sequence number 19 in AZ names a state-determined FSS violation dated 2018-01-09 and an EPA-determined 262.D violation dated 2017-02-15, which are two different violations. A further 454 facility and sequence pairs span more than one activity location, which is why the location belongs in the key too. At CTD021816889 the sequence number 302 names a 279.H violation determined by Connecticut on 2016-09-02 and an XXS violation determined by New Jersey on 2017-05-24.
    - The key was checked for internal consistency. Across the whole file no key carries two values of `VIOL_TYPE` or two values of `RESPONSIBLE_AGENCY`, so the violation's own attributes are constant within the key and the collapse takes them safely from the first row. Exactly one key carries two `DETERMINED_DATE` values and one carries two `ACTUAL_RTC_DATE` values, namely `HANDLER_ID` WYR000210260 at activity location WY under sequence 2 and determining agency S, determined on 2011-03-10 and on 2011-03-23, and both of its records fall outside the window. The fields that do vary within the key, the citations and the links to evaluations and enforcement actions, are aggregated over every row of the violation rather than read off the collapsed one (Decision 21).
- **Considerations**
    - Counting raw rows instead of distinct violations would inflate every panel count by the number of evaluations, enforcement actions, and citations a violation happened to touch, which is precisely the signal a user would want to study separately.
- **Impact**
    - The collapse takes 2,126,109 violation records to 1,031,959 violations (48.54% of the row count), so a violation spans 2.06 records on average.

### Decision 18. Month Assignment ###
- **Decision**
    - A violation belongs to the calendar month of its `DETERMINED_DATE`, the date the agency determined the violation exists.
- **Details**
    - `DETERMINED_DATE` is populated and parseable on every violation record in the data, so no violation is dropped for a missing or malformed date.
    - Violations determined outside 2015-2023 fall outside the panel window and are excluded.
- **Considerations**
    - The determination date is not the evaluation date. Across the 251,893 distinct pairs of a window violation and an evaluation linked to it, the determination falls after the evaluation started on 7.4 percent of the pairs, on the same day on 77.3 percent, and before the evaluation started on 15.3 percent. A determination can wait on sample results or on a legal review, and a violation can be linked to several evaluations including later follow-up inspections, which is what places a determination before the start of one of its own linked evaluations. 29,653 of the 206,708 window violations (14.35%) are linked to more than one evaluation. Anchoring the panel on the determination rather than on the evaluation keeps the violation on the date the agency actually recorded it as a violation.
- **Impact**
    - Excluded for an unparseable or blank date, 0 violations (0.00%).
    - Excluded as outside the window, 825,251 violations (79.97% of the 1,031,959 distinct violations).

### Decision 19. FRS Linkage ###
- **Decision**
    - Every facility-month carries `FRS_ID` on the same rule as Decision 4.
- **Details**
    - The link, the source file, and the verification of one-to-one mapping are identical to Decision 4 and are not repeated here.
    - The same site clustering applies. This panel holds 191 registry identifiers shared by two or more facilities, covering 392 of its 38,618 facilities (1.02 percent), and the widest case is `FRS_ID` 110000344182, carried by the four West Virginia facilities WVD005012851, WVR000523290, WVR000533646, and WVR000548222.
- **Impact**
    - 38,609 of the 38,618 panel facilities (99.98%) link to an FRS registry identifier. The unmatched remainder is 9 facilities (0.02%) covering 972 facility-months (0.02% of the 4,170,744 panel facility-months).

### Decision 20. Facility Attributes ###
- **Decision**
    - The same four facility-level attributes as Decision 5 are taken from the facility snapshot columns riding on the violation records, fixed at one value per facility, and repeated across all 108 of its months.
- **Details**
    - The value used is the value on the facility's most recently determined violation for the three state and region attributes, and the last non-missing value for `CE_LAND_TYPE`.
    - The attributes are drawn from the violation records of this panel rather than copied from the other two, so a facility present in more than one file can in principle carry a different snapshot in each.
- **Considerations**
    - The attributes are constant within facility in the data except for 3 facilities (0.01% of 38,618) that carry two `HANDLER_ACTIVITY_LOCATION` values across their violations, and the most-recent rule fixes those deterministically. `STATE` and `REGION` are single-valued for every facility in the panel.
    - `LAND_TYPE` is blank on 3.21 percent of window violations (6,637 of 206,708), which is why the rule takes the last non-missing value rather than the value on the latest record.
- **Impact**
    - `CE_LAND_TYPE` remains empty for 2,179 facilities (5.64% of 38,618) whose violations never record a land type, and the other three attributes are filled for every facility.
    - `CE_ACTIVITY_STATE` differs from `CE_LOCATION_STATE` for 23 facilities (0.06%).

### Decision 21. Elements Included from `CE_MASTER.csv` ###
- **Decision**
    - Each facility-month carries three groups of violation content, namely descriptive fields for the month's violations, count columns with their 0/1 indicators, and per-type count columns with their indicators. All other `CE_MASTER` elements stay out of the panel.
- **Details**
    - Month-level descriptive fields, empty when the month has no violation. Months holding more than one violation join the multi-valued fields with semicolons in determined-date order.

      | Element | Source variable | Description |
      | --- | --- | --- |
      | `CE_VIOL_STATE` | `VIOL_ACTIVITY_LOCATION` | The state whose agency regulates the activity that was violated. |
      | `CE_VIOL_RESP_AGENCY` | `RESPONSIBLE_AGENCY` | The agencies responsible for the month's violations afterwards, distinct values. This is a separate field from the determining agency and carries a few codes beyond state and federal, so it is kept as a string rather than split into counts. |
      | `CE_CITATION` | `CITATION` | The regulatory citations of the month's violations, each prefixed with its own `CITATION_OWNER` as OWNER-CITATION, for example HQ-262.34(a) or OH-279-54(C)(1), so a state code and a federal code that read alike stay distinct. |
      | `CE_CITATION_TYPE` | `CITATION_TYPE` | The month's distinct citation-origin codes, sorted, where FR is a federal regulation, SR a state regulation, SS a state statute, FS a federal statute, PC a permit condition, and OC another citation. |
      | `CE_CITATION_NUM` | `CITATION` | Count of distinct OWNER-CITATION pairs in the month. |
      | `CE_RTC_DATE` | `ACTUAL_RTC_DATE` | The distinct dates on which the month's violations returned to compliance, in determined-date order and written as YYYYMMDD. Two violations that returned on the same day collapse to a single entry, so the number of entries is not the number of violations that returned, which is `CE_TOTAL_VIOL` minus `CE_TOTAL_OPEN`. A return can fall in a later month than the row, and in 2024-2026 for violations determined late in the window, so the field describes violations determined in the month rather than compliance restored during it. |

    - Count and indicator columns, 0 on months with no violation. `CE_VIOL_EVAL_NUM` and `CE_VIOL_ENF_NUM` are the fields that vary within the violation key, so they are counted over the uncollapsed rows on the same evaluation and enforcement keys the companion panels use.

      | Element | Source rule | Description |
      | --- | --- | --- |
      | `CE_ANY_VIOL`, `CE_TOTAL_VIOL` | all violations | Violations determined in the month. |
      | `CE_ANY_STATE_VIOL`, `CE_TOTAL_STATE_VIOL` | `VIOL_DETERMINED_BY_AGENCY == "S"` | Violations determined by a state agency. |
      | `CE_ANY_FED_VIOL`, `CE_TOTAL_FED_VIOL` | `VIOL_DETERMINED_BY_AGENCY == "E"` | Violations determined by EPA. |
      | `CE_ANY_OPEN`, `CE_TOTAL_OPEN` | no `ACTUAL_RTC_DATE` | Violations still open as of the data pull. The complement, violations that returned to compliance, is `CE_TOTAL_VIOL` minus `CE_TOTAL_OPEN`. |
      | `CE_VIOL_EVAL_NUM` | distinct linked evaluations | Distinct evaluations linked to the month's violations, on the evaluation key of Part 1. A violation can be linked to several evaluations, so this is not a count of the month's evaluations. |
      | `CE_VIOL_ENF_NUM` | distinct linked enforcement actions | Distinct enforcement actions linked to the month's violations, on the enforcement key of Part 2. The action can be dated in a later month than the row. |

    - Per-type count columns, 0 on months with no violation. Each violation carries exactly one `VIOL_TYPE`, so the seven counts sum to `CE_TOTAL_VIOL`. Each pairs with a `CE_ANY_*` indicator on the same rule as the counts above.

      | Element | Source rule | Description |
      | --- | --- | --- |
      | `CE_ANY_262A`, `CE_TOTAL_262A` | `VIOL_TYPE == "262.A"` | Generators - General. |
      | `CE_ANY_262C`, `CE_TOTAL_262C` | `VIOL_TYPE == "262.C"` | Generators - Pre-transport. |
      | `CE_ANY_XXS`, `CE_TOTAL_XXS` | `VIOL_TYPE == "XXS"` | State statute or regulation. This is the state catch-all rather than an area of the CFR, so it records that a state wrote the violation against its own rule and says nothing about which requirement was broken. |
      | `CE_ANY_273B`, `CE_TOTAL_273B` | `VIOL_TYPE == "273.B"` | Universal Waste - Small Quantity Handlers. |
      | `CE_ANY_279C`, `CE_TOTAL_279C` | `VIOL_TYPE == "279.C"` | Used Oil - Generators. |
      | `CE_ANY_262D`, `CE_TOTAL_262D` | `VIOL_TYPE == "262.D"` | Generators - Records and Reporting. |
      | `CE_ANY_OTHER`, `CE_TOTAL_OTHER` | every other `VIOL_TYPE` | The remaining 105 codes, pooled. The panel does not carry the codes themselves, so which of the 105 fired in a month is recoverable only by joining the violation key back to `CE_MASTER.csv`. |

    - Elements of `CE_MASTER.csv` not included in the panel, grouped, with the rationale for exclusion.

      | Elements | Description | Rationale |
      | --- | --- | --- |
      | `HANDLER_NAME` | Facility legal name. | The facility is already keyed by `HANDLER_ID` and `FRS_ID`. |
      | Violation detail (`VIOL_TYPE_OWNER`, `VIOL_SHORT_DESC`, `SCHEDULED_COMPLIANCE_DATE`, `RTC_QUALIFIER`, `FORMER_CITATION`, `VIOL_LAST_CHANGE`) | The violation's short description, its scheduled compliance date, the qualifier on its return to compliance, its former citation, and its change stamp. | Violation-level detail beneath the month grain, recoverable by joining the violation key back to `CE_MASTER.csv`. |
      | Citation key (`CITATION_SEQ`) | The sequence number of the citation row within the violation. | Record machinery, not facility-month content. The panel keeps the owner-prefixed citation and the citation-type code, and the sequence is recoverable by the same join. |
      | Evaluation, enforcement, and supplemental project fields | The records the violation key rides on in `CE_MASTER.csv`. | Documented in Part 1 or Part 2, or left to a join on the violation key, with only the distinct-count links carried here. |

- **Considerations**
    - The six typed codes are the most common in the window, and the cut is taken at the largest break in the frequency ranking. Measured by the share of the 52,155 active facility-months in which a code appears, the six run from 262.A at 38.02 percent down to 262.D at 14.72 percent, and the next code, 262.B, appears in 8.87 percent, a drop of two fifths, where no step above it falls by more than a quarter. The remaining 105 codes are individually smaller and pool into `CE_TOTAL_OTHER` rather than adding a hundred near-empty column pairs.
    - Violation determining agency is "S" or "E" for every violation in the window, so the state and federal split is exhaustive. Any other agency code, if it ever appeared, would count toward neither.
    - The month's cells are far denser than in the other two panels, because one inspection routinely produces several findings at once. An active facility-month holds 3.96 violations on average and 3 at the median, and 2,847 of them hold twelve or more, where an active month in the evaluation or enforcement panel rarely holds more than one.
- **Impact**
    - Violation types among the 206,708 window violations are 262.A with 41,889 (20.27%), 262.C with 40,826 (19.75%), XXS with 25,505 (12.34%), 273.B with 21,388 (10.35%), 279.C with 10,897 (5.27%), 262.D with 9,652 (4.67%), and OTHER with 56,551 (27.36%). The six typed codes together cover 150,157 window violations (72.64%). The largest members of OTHER by window violation count are 265.I TSD IS-Container Use and Management with 5,482, 262.B Generators - Manifest with 5,278, and 262.M with 4,554.
    - Measured against the 52,155 facility-months that hold at least one violation, the typed indicators fire on 262.A in 19,828 (38.02%), 262.C in 16,906 (32.41%), XXS in 14,040 (26.92%), 273.B in 10,631 (20.38%), 279.C in 8,502 (16.30%), 262.D in 7,678 (14.72%), and OTHER in 23,700 (45.44%).
    - The window's violations split into 182,445 determined by a state agency (88.26%) and 24,263 by EPA (11.74%). `RESPONSIBLE_AGENCY` afterwards is S on 182,005, E on 23,712, blank on 982 (0.48%), C on 8, and B on 1.
    - Open violations, those with no `ACTUAL_RTC_DATE`, number 6,333 (3.06% of the 206,708). Of the violations that returned, 9,026 (4.37%) carry a return date after 2023-12-31, the latest being 2026-06-29, and 155,123 (75.04%) returned in a later month than they were determined.
    - Citations are absent on 45,775 window violations (22.14%). On the 52,155 active facility-months, `CE_CITATION`, `CE_CITATION_TYPE`, and `CE_CITATION_NUM` are all blank or zero on the same 11,416 (21.89%), and `CE_CITATION_NUM` runs to a maximum of 71, averaging 3.05 over all 52,155 active months and 3.90 over the 40,739 that carry at least one citation.
    - `CE_VIOL_EVAL_NUM` is at least 1 on every active month, exceeds 1 on 6,213 (11.91%), and reaches 95. `CE_VIOL_ENF_NUM` is 0 on 10,214 active months (19.58%), leaving 41,941 (80.42%) with a linked action, and reaches 16.
    - Blankness of the descriptive fields, measured against the 52,155 active months, is 0 for `CE_VIOL_STATE`, 352 (0.67%) for `CE_VIOL_RESP_AGENCY`, and 1,048 (2.01%) for `CE_RTC_DATE`. `CE_ANY_OPEN` fires on 1,372 active months (2.63%).
    - 35,613 of the 52,155 facility-months with violations (68.28%) hold more than one violation and use the semicolon joining, and the largest is 134 violations in one month.

### Decision 22. Violation Type Recode ###
- **Decision**
    - One violation-type code is recoded before any count column is built. `262.34(a)`, which the RCRAInfo Nationally-Defined Values page for CM&E Violation Type does not list, is read as `262.A`, the code whose description its own records carry.
- **Details**
    - `262.34(a)` is a citation, 40 CFR 262.34(a), typed into the code field on 26 window violations, and every one of those records carries "Generators - General", the description of `262.A`, so the recode reads them as that code rather than leaving a citation stranded in the type field.
    - The recode runs before the typed and OTHER counts are formed, so the 26 violations count toward `CE_TOTAL_262A` and never appear in `CE_TOTAL_OTHER`, and `262.34(a)` never appears as an OTHER code.
    - The only other codes in the file that the reference page does not list are `257.90E` and `257.91`, coal combustion residuals under 40 CFR 257 and outside Subtitle C. Their three records are determined on 2024-05-01, 2024-08-05, and 2025-03-03, so all of them fall after the window closes, no unlisted code other than the recoded one survives into the panel, and every remaining window code is nationally defined.
- **Considerations**
    - The recode is a reading of the state's own record rather than a reclassification. The records already say the violation is a general generator violation, so folding the mistyped citation into `262.A` reports what the state recorded rather than inventing a category.
- **Impact**
    - The recode moves 26 window violations from a would-be OTHER code into `262.A`. After it, the window carries 111 distinct violation-type codes, the six typed codes and 105 in OTHER.

### Decision 23. Balanced Grid and Zero Fill ###
- **Decision**
    - The panel is the full cross of the 38,618 facilities with all 108 months, on the same zero-fill convention as Decision 7.
- **Impact**
    - 52,155 facility-months (1.25% of the 4,170,744) carry at least one violation, and the remaining 4,118,589 (98.75%) are zero-filled.
    - The panel carries 206,708 violations in total, of which 6,333 (3.06%) were still open as of the data pull.

## Institutional Context ##
The rules that shape all three panels are described in the compliance and enforcement brief at [`docs/institutional_briefs/03_compliance_and_enforcement.md`](../../../docs/institutional_briefs/03_compliance_and_enforcement.md). The division of authority between EPA and the states, which is why the enforcement panel splits actions into state and federal and why organizational codes keep their state prefix, is described in [`docs/institutional_briefs/04_state_authorization.md`](../../../docs/institutional_briefs/04_state_authorization.md). The identifier system behind `HANDLER_ID` and `FRS_ID` is described in [`docs/institutional_briefs/09_facility_identifiers.md`](../../../docs/institutional_briefs/09_facility_identifiers.md).
