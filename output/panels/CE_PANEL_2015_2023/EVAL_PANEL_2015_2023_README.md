# `EVAL_PANEL_2015_2023` Decision Record #

## Purpose ##
This document records every construction decision behind `EVAL_PANEL_2015_2023.csv`, the facility-month panel of compliance evaluations, built by `code/modules/03_panels/rcrainfo/03_panel_eval_2015_2023.R`. The panel is also written as an `.rds` twin carrying the exact column types, because a plain CSV records none of them and a reader that re-guesses them mistypes the sparse columns. Each decision states the outcome that was adopted, the details of how it is implemented, the considerations behind it where alternatives were worth weighing, and the measured impact on the data. Every count is taken from the actual input and output files, and every percentage states the baseline it is measured against. The decisions appear in the order in which they act on the data, so reading top to bottom follows the construction of the panel from `CE_MASTER.csv` to the final CSV.

Two companion panels share this folder, are drawn from the same source, and cover the same 108 calendar months. `ENF_PANEL_2015_2023.csv` holds enforcement actions and `VIOL_PANEL_2015_2023.csv` holds determined violations, and each carries its own decision record beside it. The three are separate files with separate universes, so nothing below documents their contents beyond the joins that reach them.

## Construction Decisions ##

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
    - The panel holds 9,489,528 facility-months, exactly 87,866 facilities times 108 months, in 31 columns.

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
    - Four facility-level attributes are taken from the facility snapshot columns that ride on the evaluation records, fixed at one value per facility, and repeated across all 108 of its months. A fifteen-column coordinate slot block is taken from `HD_MASTER.csv` on the same terms, one block per facility repeated across its months, and it is the only thing this panel takes from the Handler master.

      | Element | Source variable | Description |
      | --- | --- | --- |
      | `CE_ACTIVITY_STATE` | `HANDLER_ACTIVITY_LOCATION` | Location of the agency regulating the facility. |
      | `CE_LOCATION_STATE` | `STATE` | State postal code where the facility is located. |
      | `CE_EPA_REGION` | `REGION` | EPA region in which the facility is located. |
      | `CE_LAND_TYPE` | `LAND_TYPE` | Current ownership status of the land on which the facility is located. |

      Coordinate slots, from `HD_MASTER.csv` rather than from `CE_MASTER.csv`, which is why they keep the `HD_` prefix. The Handler master ranks every coordinate pair available for a facility, and the block is taken whole from the facility's most recent handler record. The ranking, the source codes, and the reason a pair can appear in one slot and not another are documented in the [Handler master module README](../../../code/modules/02_modular_master_files/rcrainfo/README.md#coordinate-slots). The same block, under the same names, is carried by all five panels.

      | Element | Source variable | Description |
      | --- | --- | --- |
      | `HD_PREFERRED_LATITUDE` | `PREFERRED_LATITUDE` | Latitude of the pair to use for the facility, in decimal degrees. |
      | `HD_PREFERRED_LONGITUDE` | `PREFERRED_LONGITUDE` | Longitude of the pair to use for the facility, in decimal degrees. |
      | `HD_PREFERRED_COORD_SOURCE` | `PREFERRED_COORD_SOURCE` | Where that pair came from, namely `MANUAL` for a hand-placed pair, `FRS` for the Facility Registry Service pair, `HD` for the pair the facility reported, and `HD_OTHER` for a pair on another of the facility's records. |
      | `HD_LATITUDE_2`-`HD_LATITUDE_5` | `LATITUDE_2`-`LATITUDE_5` | Latitudes of the pairs the preference order set aside, empty where the facility has no further pair. |
      | `HD_LONGITUDE_2`-`HD_LONGITUDE_5` | `LONGITUDE_2`-`LONGITUDE_5` | Longitudes of those pairs. |
      | `HD_COORD_SOURCE_2`-`HD_COORD_SOURCE_5` | `COORD_SOURCE_2`-`COORD_SOURCE_5` | Where each of those pairs came from, on the same four codes. |

- **Details**
    - The coordinate block is the panel's only geography beyond the state and region codes above, since the evaluation records carry no coordinates of their own. A facility whose block is empty is one that no source can place, and those facilities are listed for a manual search in `HD_COORDINATE_MANUAL_REVIEW.csv`. Slot coverage on this panel is measured on the next rebuild and recorded here then, since the block is new to this schema.
    - The value used is the last non-missing value in evaluation start-date order, so each attribute reflects the facility's most recent evaluation that recorded it.
    - These columns are snapshots carried on evaluation records, not a notification history, so they hold one value per facility rather than one per facility-month.
- **Considerations**
    - The attributes are constant within facility in the data except for 18 facilities (0.02% of 87,866) that carry two `HANDLER_ACTIVITY_LOCATION` values across their evaluations, and the most-recent rule fixes those deterministically instead of leaving two competing values.
    - `LAND_TYPE` is blank on 4.51 percent of window evaluation records (9,123 of 202,501), which is why the rule takes the last non-missing value rather than the value on the latest record.
- **Impact**
    - `CE_LAND_TYPE` remains empty for 6,797 facilities (7.74% of 87,866) whose evaluations never record a land type, and the other three attributes are filled for every facility.
    - `CE_ACTIVITY_STATE` differs from `CE_LOCATION_STATE` for 78 facilities (0.09%), which are facilities regulated by an agency outside the state they sit in.

### Decision 6. Elements Included from `CE_MASTER.csv` ###
- **Decision**
    - Each facility-month carries four groups of evaluation content, namely descriptive fields for the month's evaluations, count columns by evaluation type, 0/1 indicator columns derived from the counts, and 0/1 context indicators for the month's evaluations. All other `CE_MASTER` elements stay out of the panel.
- **Details**
    - Month-level descriptive fields, empty when the month has no evaluation.

      | Element | Source variable | Description |
      | --- | --- | --- |
      | `CE_EVAL_STATE` | `EVAL_ACTIVITY_LOCATION` | Location of the agency conducting the evaluation, distinct values in start-date order. |
      | `CE_EVAL_AGENCY` | `EVAL_AGENCY` | Agency responsible for conducting the evaluation, distinct values in start-date order. |
      | `CE_EVAL_SUBORG` | `EVAL_SUBORGANIZATION` | Suborganization codes within the evaluating agency, each prefixed with its own evaluation state as STATE-SUBORG, for example IL-CD, so codes that read alike in different states stay distinct. |
      | `CE_EVAL_DATE` | `NOC_DATE` | The distinct dates on which the month's evaluations ended, meaning the facility was notified that no violation was found or that the violations found had returned to compliance, in evaluation start-date order and written as YYYYMMDD. |
      | `CE_EVAL_DATE_NUM` | `NOC_DATE` | Count of distinct end dates in the month, so a reader knows how many entries `CE_EVAL_DATE` holds without splitting it. It is 0 on months whose evaluations carry no end date at all. |

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

    - Months holding more than one evaluation join the multi-valued descriptive fields with semicolons in evaluation start-date order.
    - Two evaluations that ended on the same day collapse to a single entry in `CE_EVAL_DATE`, so the number of entries is the number of distinct end dates rather than the number of evaluations that ended, and `CE_EVAL_DATE_NUM` reports exactly that number. An end date can also fall in a later month than the row that carries it, because an evaluation starting in the month can end long afterwards.
    - Elements of `CE_MASTER.csv` not included in the panel, grouped, with the rationale for exclusion.

      | Elements | Description | Rationale |
      | --- | --- | --- |
      | `HANDLER_NAME` | Facility legal name. | The facility is already keyed by `HANDLER_ID` and `FRS_ID`. |
      | `EVAL_RESPONSIBLE_PERSON` | Code of the staff member responsible for the evaluation. | A staff identifier rather than facility-month content, left out on the same rule the summary-table configs follow, and recoverable by joining the evaluation key back to `CE_MASTER.csv`. |
      | `EVAL_LAST_CHANGE` | Stamp of the last edit made to the evaluation record. | Populated on all 202,501 window evaluations but describing when RCRAInfo was edited rather than what happened at the facility, so it is record machinery. |
      | Remaining attribute flags (`SAMPLING`, `NOT_SUBTITLE_C`) | Samples were taken during the evaluation, and the evaluation addressed something other than Subtitle C requirements. | Coded "1" on 482 (0.24%) and 247 (0.12%) of the 202,501 window evaluations, an order of magnitude rarer than the two flags the panel does keep and too rare to earn an indicator column. |
      | Child-record keys (`VIOL_SEQ`, `REQUEST_SEQ`, `CITATION_SEQ`, `CAFO_SEQ`, `SEP_SEQ`, `ENF_IDENTIFIER`) | Sequence numbers and identifiers of the records that repeat the evaluation key. | Record machinery, not facility-month content. |
      | Evaluation detail (`EVAL_TYPE_DESC`, `FOCUS_AREA`, `FOCUS_AREA_DESC`) | Type descriptions and focus areas of the individual evaluation. | Evaluation-level detail beneath the month grain, recoverable by joining the evaluation key back to `CE_MASTER.csv`. |
      | Information-request fields (`DATE_OF_REQUEST`, `DATE_RESPONSE_RECEIVED`, `REQUEST_AGENCY`, `REQUEST_ACTIVITY_LOCATION`) | RCRA 3007 information requests attached to the evaluation. | Child records of the evaluation, recoverable by the same join. |
      | Violation fields (`VIOL_ACTIVITY_LOCATION`, `VIOL_TYPE`, `VIOL_TYPE_OWNER`, `VIOL_SHORT_DESC`, `DETERMINED_DATE`, `VIOL_DETERMINED_BY_AGENCY`, `RESPONSIBLE_AGENCY`, `SCHEDULED_COMPLIANCE_DATE`, `ACTUAL_RTC_DATE`, `RTC_QUALIFIER`, `CITATION`, `CITATION_OWNER`, `CITATION_TYPE`, `FORMER_CITATION`, `VIOL_LAST_CHANGE`) | Determined violations with their citations, compliance schedules, and return-to-compliance dates. | Carried by the companion violation panel documented in [`VIOL_PANEL_2015_2023_README.md`](VIOL_PANEL_2015_2023_README.md), on the date the violation was determined rather than on the evaluation's month. The facility-month here keeps the evaluation-level `FOUND_VIOLATION` signal. |
      | Enforcement fields (`ENF_ACTIVITY_LOCATION`, `ENF_TYPE`, `ENF_TYPE_DESC`, `ENF_ACTION_DATE`, `ENF_AGENCY`, `DOCKET_NUMBER`, `ATTORNEY`, `ENF_RESPONSIBLE_PERSON`, `ENF_SUBORGANIZATION`, `CA_COMPONENT`, `FA_REQUIREMENT`, appeal and disposition fields, `RESPONDENT_NAME`, `LEAD_AGENCY`, `ENF_LAST_CHANGE`, `PROPOSED_AMOUNT`, `FINAL_MONETARY_AMOUNT`, `PAID_AMOUNT`, `FINAL_COUNT`, `FINAL_AMOUNT`) | Enforcement actions with their agencies, dockets, dispositions, and penalty amounts. | Carried by the companion enforcement panel documented in [`ENF_PANEL_2015_2023_README.md`](ENF_PANEL_2015_2023_README.md), on its own action date rather than on the evaluation's month. |
      | Supplemental environmental project fields (`SEP_TYPE`, `SEP_TYPE_DESC`, `EXPENDITURE_AMOUNT`, `SCHEDULED_COMPLETION_DATE`, `ACTUAL_COMPLETION_DATE`, `SEP_DEFAULTED_DATE`) | Supplemental environmental projects tied to enforcement. | Child records of the enforcement action, recoverable by joining the enforcement key back to `CE_MASTER.csv`. |

- **Considerations**
    - The five evaluation types with their own columns are the five most common codes in the window, and the remaining ten codes are individually rare and pool into `CE_TOTAL_OTHER` rather than adding ten near-empty column pairs.
    - `U` (undetermined) is deliberately not counted as a found violation, so `CE_EVALS_WITH_VIOL` is a strict count of evaluations that discovered violations.
    - The end date is carried as the raw YYYYMMDD stamp rather than as a parsed date, so the panel writes the value RCRAInfo recorded and a reader can see it verbatim. Pairing it with an explicit count was chosen over splitting it into year and month columns, because a month can hold several end dates and a split into two columns forces the reader to pair entries by position.
- **Impact**
    - Evaluation types among the 202,501 window evaluations are CEI with 111,972 (55.29%), NRR with 29,145 (14.39%), FCI with 21,519 (10.63%), FRR with 9,087 (4.49%), FSD with 6,473 (3.20%), and OTHER with 24,305 (12.00%).
    - `FOUND_VIOLATION` among the same baseline is "1" on 60,041 evaluations (29.65%), "0" on 140,793 (69.53%), and "U" on 1,667 (0.82%).
    - Blankness of the descriptive fields, measured against the 178,762 facility-months that hold at least one evaluation, is 0 for `CE_EVAL_STATE` and `CE_EVAL_AGENCY`, 60,727 (33.97%) for `CE_EVAL_SUBORG`, and 173,623 (97.13%) for `CE_EVAL_DATE`, which is the same 173,623 months on which `CE_EVAL_DATE_NUM` is 0. `NOC_DATE` exists on only 5,354 window evaluations (2.64%), so the end-date columns are sparse by nature, and `CE_EVAL_DATE_NUM` reaches a maximum of 5.
    - The context indicators mark few months against the same baseline, with citizen complaint on 4,904 (2.74%) and multimedia inspection on 4,695 (2.63%).
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

## Proposed Cross-Panel Count Fields ##
This part is a design note rather than a record of anything the panel currently carries. It sketches two count fields that would connect this panel to its companions through the linkage `CE_MASTER.csv` already holds, and it sets out the questions that have to be answered before either is built. Nothing here is implemented.

`CE_MASTER.csv` is evaluation-centred. One row is an evaluation crossed with its 3007 request, violation, enforcement action, supplemental environmental project, and citation entries, so a single evaluation fans out into as many rows as it has child records of each kind. This panel takes the evaluation slice of that structure and places it on the evaluation's start month, while the enforcement panel places an action on its action date and the violation panel places a violation on its determined date. The proposed fields would let a facility-month here report how many of the other panels' records are linked to it, without a user having to rejoin `CE_MASTER.csv` by hand.

- `CE_EVAL_VIOL_NUM` would count the distinct determined violations linked to the month's evaluations, keyed on `VIOL_SEQ` within the evaluation. It is not the same measure as the existing `CE_EVALS_WITH_VIOL`, which counts how many evaluations found at least one violation. A single evaluation that determined four violations contributes 1 to `CE_EVALS_WITH_VIOL` and 4 to `CE_EVAL_VIOL_NUM`.
- `CE_EVAL_ENF_NUM` would count the distinct enforcement actions linked to the month's evaluations, keyed on `ENF_IDENTIFIER`. It reports how much enforcement the month's evaluations gave rise to, measured on the evaluation's month rather than on the actions' own dates.

### Questions to settle before building ###
- Counts must be taken on distinct child keys, not on rows. Because `CE_MASTER.csv` crosses every child kind against every other, a naive row count multiplies violations by enforcement actions and returns a figure that means nothing.
- Every count sits on this panel's month, which is not the month the linked record carries. `CE_EVAL_ENF_NUM` would place enforcement on the evaluation's start month even though the enforcement panel places the same action on its action date, and the two months can fall in different cycles. The fields answer how much is linked to what happened this month here, and they must be documented as such rather than read as activity dated to the month.
- The three panels have different universes, so a linked record can point outside this panel's population. An enforcement action linked to an evaluation would be counted by `CE_EVAL_ENF_NUM` whether or not that action's facility is itself in the enforcement panel. Whether the count should be restricted to records that also appear in the companion panel is a modelling choice that changes what the field means.
- The undetermined code should be handled the same way it already is. `CE_EVALS_WITH_VIOL` counts only `FOUND_VIOLATION == "1"` and excludes `"0"` and `"U"`, and any violation count added here should say explicitly whether it follows the same rule so the two violation measures stay comparable.

## Institutional Context ##
The rules that shape this panel are described in the compliance and enforcement brief at [`docs/institutional_briefs/03_compliance_and_enforcement.md`](../../../docs/institutional_briefs/03_compliance_and_enforcement.md). The division of authority between EPA and the states, which is why an evaluation carries its own conducting agency and why organizational codes keep their state prefix, is described in [`docs/institutional_briefs/04_state_authorization.md`](../../../docs/institutional_briefs/04_state_authorization.md). The identifier system behind `HANDLER_ID` and `FRS_ID` is described in [`docs/institutional_briefs/09_facility_identifiers.md`](../../../docs/institutional_briefs/09_facility_identifiers.md).
