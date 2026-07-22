# `VIOL_PANEL_2015_2023` Decision Record #

## Purpose ##
This document records every construction decision behind `VIOL_PANEL_2015_2023.csv`, the facility-month panel of determined violations, built by `code/modules/03_panels/rcrainfo/05_panel_viol_2015_2023.R`. The panel is also written as an `.rds` twin carrying the exact column types, because a plain CSV records none of them and a reader that re-guesses them mistypes the sparse columns. Each decision states the outcome that was adopted, the details of how it is implemented, the considerations behind it where alternatives were worth weighing, and the measured impact on the data. Every count is taken from the actual input and output files, and every percentage states the baseline it is measured against. The decisions appear in the order in which they act on the data, so reading top to bottom follows the construction of the panel from `CE_MASTER.csv` to the final CSV.

Two companion panels share this folder, are drawn from the same source, and cover the same 108 calendar months. `EVAL_PANEL_2015_2023.csv` holds compliance evaluations and `ENF_PANEL_2015_2023.csv` holds enforcement actions, and each carries its own decision record beside it. The three are separate files with separate universes, so nothing below documents their contents beyond the joins and link counts that reach them.

## Construction Decisions ##

### Decision 1. Universe and Unit of Observation ###
- **Decision**
    - The panel is a balanced facility-month panel keyed on `HANDLER_ID`, `YEAR`, and `MONTH`. It covers the 108 calendar months from January 2015 through December 2023, and a facility is included if at least one of its violations was determined in that window. Every included facility carries all 108 months.
- **Details**
    - Each facility-month represents one facility in one calendar month. Months are indexed by `YEAR` (2015-2023) and `MONTH` (1-12).
    - A facility contributes exactly 108 facility-months regardless of how many months hold a violation, and months without one are zero-filled per Decision 8.
    - The source is `CE_MASTER.csv`, the compliance monitoring and enforcement master file compiled from RCRAInfo's CM&E module.
    - The unit, the month index, and the zero-fill convention match the companion panels exactly, so the files can be joined on `HANDLER_ID`, `YEAR`, and `MONTH`.
- **Considerations**
    - A determined violation is a dated finding rather than a period report, so the monthly grain used by the companion panels carries over without change.
    - Membership is defined by the outcome the panel measures, so the file describes how many violations are found at facilities that had at least one violation and not the incidence of violations across the regulated universe.
    - The universe is close to but not the same as the evaluation panel's. Nearly every facility with a window violation also has a window evaluation, but four facilities carry a determined violation in the window without either a window evaluation or a window enforcement action, so a join across the three files has to state which side it keeps.
- **Impact**
    - `CE_MASTER.csv` holds 2,872,361 records covering 306,739 distinct facilities. Of these, 2,126,109 records carry a violation, covering 147,048 distinct facilities and collapsing to 1,031,959 distinct violations (Decision 2).
    - Violations determined in 2015-2023 number 206,708 (20.03% of the 1,031,959 distinct violations), at 38,618 distinct facilities (26.26% of the 147,048 facilities carrying any violation).
    - The panel holds 4,170,744 facility-months, exactly 38,618 facilities times 108 months, in 38 columns.
    - Of the 38,618 panel facilities, 38,594 (99.94%) also appear in the evaluation panel and 31,303 (81.06%) also appear in the enforcement panel, and 4 appear in neither.

### Decision 2. Violation Identity and Deduplication ###
- **Decision**
    - One violation is one distinct combination of `HANDLER_ID`, `VIOL_ACTIVITY_LOCATION`, `VIOL_SEQ`, and `VIOL_DETERMINED_BY_AGENCY`, the key the CM&E structure chart uses to link a citation row back to the violation it belongs to, and every count in the panel is a count of these distinct violations.
- **Details**
    - `CE_MASTER.csv` repeats the violation key across the evaluations that found the violation, the enforcement actions that address it, and its own citation rows, so one violation can appear on many rows. The panel collapses the file back to one row per violation before any counting.
    - `VIOL_SEQ` is a sequence within a facility and activity location rather than an identifier of one violation, so it cannot define identity on its own. Of the 1,015,608 facility, activity location, and sequence triples in the file, 16,351 carry more than one determining agency, which is why the agency belongs in the key, and 873 of those triples fall inside the window. At AZD980735179 the sequence number 19 in AZ names a state-determined FSS violation dated 2018-01-09 and an EPA-determined 262.D violation dated 2017-02-15, which are two different violations. A further 454 facility and sequence pairs span more than one activity location, which is why the location belongs in the key too. At CTD021816889 the sequence number 302 names a 279.H violation determined by Connecticut on 2016-09-02 and an XXS violation determined by New Jersey on 2017-05-24.
    - The key was checked for internal consistency. Across the whole file no key carries two values of `VIOL_TYPE` or two values of `RESPONSIBLE_AGENCY`, so the violation's own attributes are constant within the key and the collapse takes them safely from the first row. Exactly one key carries two `DETERMINED_DATE` values and one carries two `ACTUAL_RTC_DATE` values, namely `HANDLER_ID` WYR000210260 at activity location WY under sequence 2 and determining agency S, determined on 2011-03-10 and on 2011-03-23, and both of its records fall outside the window. The fields that do vary within the key, the citations and the links to evaluations and enforcement actions, are aggregated over every row of the violation rather than read off the collapsed one (Decision 6).
- **Considerations**
    - Counting raw rows instead of distinct violations would inflate every panel count by the number of evaluations, enforcement actions, and citations a violation happened to touch, which is precisely the signal a user would want to study separately.
- **Impact**
    - The collapse takes 2,126,109 violation records to 1,031,959 violations (48.54% of the row count), so a violation spans 2.06 records on average.

### Decision 3. Month Assignment ###
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

### Decision 4. FRS Linkage ###
- **Decision**
    - Every facility-month carries `FRS_ID`, the EPA FRS `REGISTRY_ID`, so the panel can be joined to other EPA programs through a common facility identifier.
- **Details**
    - The link comes from the FRS Program Links file (`data/frs/FRS_PROGRAM_LINKS.csv`), matching the facility's RCRAInfo identifier (`HANDLER_ID`) against `PGM_SYS_ID` on the rows where `PGM_SYS_ACRNM == "RCRAINFO"`.
    - The mapping was verified to be strictly one-to-one on the RCRAINFO rows. The file holds 1,591,859 RCRAINFO rows with 1,591,859 distinct `PGM_SYS_ID` values and zero identifiers mapped to more than one `REGISTRY_ID`, so the join cannot fan out the panel.
    - The reverse direction is not injective. A registry identifier names a physical site, and a site that re-registered under RCRA carries every one of its RCRAInfo identifiers on the same `FRS_ID`. In this panel 191 registry identifiers are shared by two or more facilities, covering 392 of its 38,618 facilities (1.02 percent), and the widest case is `FRS_ID` 110000344182, carried by the four West Virginia facilities WVD005012851, WVR000523290, WVR000533646, and WVR000548222. Analyses keyed on `FRS_ID` should expect these clusters rather than assume one facility per registry identifier.
    - `FRS_ID` is empty when no RCRAINFO link exists for the facility.
- **Impact**
    - 38,609 of the 38,618 panel facilities (99.98%) link to an FRS registry identifier. The unmatched remainder is 9 facilities (0.02%) covering 972 facility-months (0.02% of the 4,170,744 panel facility-months).

### Decision 5. Facility Attributes ###
- **Decision**
    - Four facility-level attributes are taken from the facility snapshot columns that ride on the violation records, fixed at one value per facility, and repeated across all 108 of its months. A fifteen-column coordinate slot block is taken from `HD_MASTER.csv` on the same terms, one block per facility repeated across its months, and it is the only thing this panel takes from the Handler master.

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
    - The coordinate block is the panel's only geography beyond the state and region codes above, since the violation records carry no coordinates of their own. A facility whose block is empty is one that no source can place, and those facilities are listed for a manual search in `HD_COORDINATE_MANUAL_REVIEW.csv`. Slot coverage on this panel is measured on the next rebuild and recorded here then, since the block is new to this schema.
    - The value used is the value on the facility's most recently determined violation for the three state and region attributes, and the last non-missing value for `CE_LAND_TYPE`.
    - These columns are snapshots carried on violation records, not a notification history, so they hold one value per facility rather than one per facility-month.
    - The attributes are drawn from the violation records of this panel rather than copied from the companion panels, so a facility present in more than one file can in principle carry a different snapshot in each.
- **Considerations**
    - The attributes are constant within facility in the data except for 3 facilities (0.01% of 38,618) that carry two `HANDLER_ACTIVITY_LOCATION` values across their violations, and the most-recent rule fixes those deterministically instead of leaving two competing values. `STATE` and `REGION` are single-valued for every facility in the panel.
    - `LAND_TYPE` is blank on 3.21 percent of window violations (6,637 of 206,708), which is why the rule takes the last non-missing value rather than the value on the latest record.
- **Impact**
    - `CE_LAND_TYPE` remains empty for 2,179 facilities (5.64% of 38,618) whose violations never record a land type, and the other three attributes are filled for every facility.
    - `CE_ACTIVITY_STATE` differs from `CE_LOCATION_STATE` for 23 facilities (0.06%), which are facilities regulated by an agency outside the state they sit in.

### Decision 6. Elements Included from `CE_MASTER.csv` ###
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
      | `CE_VIOL_EVAL_NUM` | distinct linked evaluations | Distinct evaluations linked to the month's violations, on the evaluation key the evaluation panel uses. A violation can be linked to several evaluations, so this is not a count of the month's evaluations. |
      | `CE_VIOL_ENF_NUM` | distinct linked enforcement actions | Distinct enforcement actions linked to the month's violations, on the enforcement key the enforcement panel uses. The action can be dated in a later month than the row. |

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
      | Evaluation, enforcement, and supplemental project fields | The records the violation key rides on in `CE_MASTER.csv`. | Documented in [`EVAL_PANEL_2015_2023_README.md`](EVAL_PANEL_2015_2023_README.md) and [`ENF_PANEL_2015_2023_README.md`](ENF_PANEL_2015_2023_README.md), or left to a join on the violation key, with only the distinct-count links carried here. |

- **Considerations**
    - The six typed codes are the most common in the window, and the cut is taken at the largest break in the frequency ranking. Measured by the share of the 52,155 active facility-months in which a code appears, the six run from 262.A at 38.02 percent down to 262.D at 14.72 percent, and the next code, 262.B, appears in 8.87 percent, a drop of two fifths, where no step above it falls by more than a quarter. The remaining 105 codes are individually smaller and pool into `CE_TOTAL_OTHER` rather than adding a hundred near-empty column pairs.
    - Violation determining agency is "S" or "E" for every violation in the window, so the state and federal split is exhaustive. Any other agency code, if it ever appeared, would count toward neither.
    - The month's cells are far denser than in the companion panels, because one inspection routinely produces several findings at once. An active facility-month holds 3.96 violations on average and 3 at the median, and 2,847 of them hold twelve or more, where an active month in the evaluation or enforcement panel rarely holds more than one.
- **Impact**
    - Violation types among the 206,708 window violations are 262.A with 41,889 (20.27%), 262.C with 40,826 (19.75%), XXS with 25,505 (12.34%), 273.B with 21,388 (10.35%), 279.C with 10,897 (5.27%), 262.D with 9,652 (4.67%), and OTHER with 56,551 (27.36%). The six typed codes together cover 150,157 window violations (72.64%). The largest members of OTHER by window violation count are 265.I TSD IS-Container Use and Management with 5,482, 262.B Generators - Manifest with 5,278, and 262.M with 4,554.
    - Measured against the 52,155 facility-months that hold at least one violation, the typed indicators fire on 262.A in 19,828 (38.02%), 262.C in 16,906 (32.41%), XXS in 14,040 (26.92%), 273.B in 10,631 (20.38%), 279.C in 8,502 (16.30%), 262.D in 7,678 (14.72%), and OTHER in 23,700 (45.44%).
    - The window's violations split into 182,445 determined by a state agency (88.26%) and 24,263 by EPA (11.74%). `RESPONSIBLE_AGENCY` afterwards is S on 182,005, E on 23,712, blank on 982 (0.48%), C on 8, and B on 1.
    - Open violations, those with no `ACTUAL_RTC_DATE`, number 6,333 (3.06% of the 206,708). Of the violations that returned, 9,026 (4.37%) carry a return date after 2023-12-31, the latest being 2026-06-29, and 155,123 (75.04%) returned in a later month than they were determined.
    - Citations are absent on 45,775 window violations (22.14%). On the 52,155 active facility-months, `CE_CITATION`, `CE_CITATION_TYPE`, and `CE_CITATION_NUM` are all blank or zero on the same 11,416 (21.89%), and `CE_CITATION_NUM` runs to a maximum of 71, averaging 3.05 over all 52,155 active months and 3.90 over the 40,739 that carry at least one citation.
    - `CE_VIOL_EVAL_NUM` is at least 1 on every active month, exceeds 1 on 6,213 (11.91%), and reaches 95. `CE_VIOL_ENF_NUM` is 0 on 10,214 active months (19.58%), leaving 41,941 (80.42%) with a linked action, and reaches 16.
    - Blankness of the descriptive fields, measured against the 52,155 active months, is 0 for `CE_VIOL_STATE`, 352 (0.67%) for `CE_VIOL_RESP_AGENCY`, and 1,048 (2.01%) for `CE_RTC_DATE`. `CE_ANY_OPEN` fires on 1,372 active months (2.63%).
    - 35,613 of the 52,155 facility-months with violations (68.28%) hold more than one violation and use the semicolon joining, and the largest is 134 violations in one month.

### Decision 7. Violation Type Recode ###
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

### Decision 8. Balanced Grid and Zero Fill ###
- **Decision**
    - The panel is the full cross of the 38,618 facilities with all 108 months. Months without a violation carry 0 in every count and indicator column and empty strings in the descriptive fields, and each `CE_ANY_*` indicator equals 1 exactly when its matching count is positive.
- **Details**
    - A 0 therefore means no violation was determined in that facility-month. It is never a missing value, and the count columns are never empty.
    - The facility attributes of Decision 5 and `FRS_ID` are the only columns filled on violation-free months.
    - `CE_VIOL_EVAL_NUM` and `CE_VIOL_ENF_NUM` are 0 on those months as well, which for `CE_VIOL_ENF_NUM` it shares with the active months whose violations carry no linked action, so a 0 there means no action is linked rather than that no action exists at the facility.
- **Considerations**
    - The alternative of keeping only months with violations would shrink the file by roughly a factor of eighty but would push the zero-versus-missing distinction onto every user. The explicit grid keeps facility-month time series directly usable for event studies and rate calculations without reconstruction, and it matches the companion panels so the three files align row for row on the facilities they share.
    - The grid does not know when a facility began or ceased to be regulated, so the zeros before a facility's first violation and after its last are structural rather than observed. Analyses that need an at-risk window have to build one from the notification history in `HD_MASTER.csv`.
- **Impact**
    - 52,155 facility-months (1.25% of the 4,170,744) carry at least one violation, and the remaining 4,118,589 (98.75%) are zero-filled.
    - The panel carries 206,708 violations in total, of which 6,333 (3.06%) were still open as of the data pull.

## Reading the Cross-Panel Link Counts ##
`CE_VIOL_EVAL_NUM` and `CE_VIOL_ENF_NUM` are the only fields in any of the three panels that report linked records from another slice of `CE_MASTER.csv`, and three properties govern how they must be read.

Both counts sit on this panel's month, which is not the month the linked record carries. An evaluation counted by `CE_VIOL_EVAL_NUM` sits on the violation's determined month even though the evaluation panel places it on its own start month, and the same holds for an action counted by `CE_VIOL_ENF_NUM` against the enforcement panel's action date. The fields answer how much is linked to the violations determined in this month, and they are not a count of activity dated to the month.

Both counts reach records that the companion panels do not hold, because a linked record is not restricted to the panel window. Of the 60,290 distinct evaluations linked to a window violation, 809 (1.34%) started outside 2015-2023 and so appear in no row of the evaluation panel, and of the 55,666 distinct enforcement actions linked to a window violation, 2,045 (3.67%) are dated outside the window and appear in no row of the enforcement panel. A user reconciling the counts against the companion files should expect this residual rather than treat it as an error.

Both counts are taken on distinct child keys over the uncollapsed rows, not on rows. Because `CE_MASTER.csv` crosses every child kind against every other, a row count would multiply evaluations by enforcement actions by citations and return a figure that means nothing, which is why Decision 6 aggregates these two fields on the evaluation and enforcement keys themselves. The linkage is complete on the evaluation side, since every one of the 432,724 window violation rows carries an evaluation key, which is why `CE_VIOL_EVAL_NUM` is at least 1 on every active month. It is not complete on the enforcement side, where 43,155 of those rows (9.97%) carry no enforcement action at all.

## Institutional Context ##
The rules that shape this panel are described in the compliance and enforcement brief at [`docs/institutional_briefs/03_compliance_and_enforcement.md`](../../../docs/institutional_briefs/03_compliance_and_enforcement.md). The division of authority between EPA and the states, which is why the panel splits violations into state-determined and EPA-determined and why a citation carries its owner as a prefix, is described in [`docs/institutional_briefs/04_state_authorization.md`](../../../docs/institutional_briefs/04_state_authorization.md). The identifier system behind `HANDLER_ID` and `FRS_ID` is described in [`docs/institutional_briefs/09_facility_identifiers.md`](../../../docs/institutional_briefs/09_facility_identifiers.md).
