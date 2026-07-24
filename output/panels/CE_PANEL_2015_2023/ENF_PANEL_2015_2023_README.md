# `ENF_PANEL_2015_2023` Decision Record #

## Purpose ##
This document records every construction decision behind `ENF_PANEL_2015_2023.csv`, the facility-month panel of enforcement actions, built by `code/modules/03_panels/rcrainfo/04_panel_enf_2015_2023.R`. The panel is also written as an `.rds` twin carrying the exact column types, because a plain CSV records none of them and a reader that re-guesses them mistypes the sparse columns. Each decision states the outcome that was adopted, the details of how it is implemented, the considerations behind it where alternatives were worth weighing, and the measured impact on the data. Every count is taken from the actual input and output files, and every percentage states the baseline it is measured against. The decisions appear in the order in which they act on the data, so reading top to bottom follows the construction of the panel from `CE_MASTER.csv` to the final CSV.

Two companion panels share this folder, are drawn from the same source, and cover the same 108 calendar months. `EVAL_PANEL_2015_2023.csv` holds compliance evaluations and `VIOL_PANEL_2015_2023.csv` holds determined violations, and each carries its own decision record beside it. The three are separate files with separate universes, so nothing below documents their contents beyond the joins that reach them.

## Construction Decisions ##

### Decision 1. Universe and Unit of Observation ###
- **Decision**
    - The panel is a balanced facility-month panel keyed on `HANDLER_ID`, `YEAR`, and `MONTH`. It covers the 108 calendar months from January 2015 through December 2023, and a facility is included if at least one of its enforcement actions is dated in that window. Every included facility carries all 108 months.
- **Details**
    - Each facility-month represents one facility in one calendar month. Months are indexed by `YEAR` (2015-2023) and `MONTH` (1-12).
    - A facility contributes exactly 108 facility-months regardless of how many months hold an action, and months without one are zero-filled per Decision 8.
    - The source is `CE_MASTER.csv`, the compliance monitoring and enforcement master file compiled from RCRAInfo's CM&E module.
    - The unit, the month index, and the zero-fill convention match the companion panels exactly, so the files can be joined on `HANDLER_ID`, `YEAR`, and `MONTH`.
    - The universes are not the same. This panel is a near subset of the evaluation panel, but 340 of its facilities receive an action in the window without an evaluation in the window, so a join of the two files has to state which side it keeps.
- **Considerations**
    - The monthly grain was chosen over an annual one because an enforcement action is a dated event rather than a period report, and a month is fine enough to order events within a year while staying coarse enough that multi-action cells are rare (Decision 6 counts them).
    - The universes were left separate rather than forced onto the evaluation panel's facility list, because that would have dropped the 340 enforcement-only facilities and would have given 56,034 facilities a full enforcement grid of zeros they never had an action to fill.
    - Membership is defined by the outcome the panel measures, so the file describes the intensity of enforcement at facilities that were subject to enforcement and not its incidence across the regulated universe.
- **Impact**
    - `CE_MASTER.csv` holds 1,928,016 enforcement records covering 131,600 distinct facilities, collapsing to 365,899 distinct enforcement actions (Decision 2).
    - Actions dated 2015-2023 number 56,098 (15.33% of the 365,899 distinct actions), at 32,172 distinct facilities (24.45% of the 131,600 facilities carrying any action).
    - The panel holds 3,474,576 facility-months, exactly 32,172 facilities times 108 months, in 24 columns.
    - 31,832 of the 32,172 facilities (98.94%) also appear in the evaluation panel.

### Decision 2. Enforcement Action Identity and Deduplication ###
- **Decision**
    - One enforcement action is one distinct combination of `HANDLER_ID`, `ENF_ACTIVITY_LOCATION`, `ENF_IDENTIFIER`, `ENF_ACTION_DATE`, and `ENF_AGENCY`, and every count in the panel is a count of these distinct actions.
- **Details**
    - `CE_MASTER.csv` repeats the enforcement key across the evaluation, violation, citation, and supplemental project rows it belongs to, so one action can appear on many rows. The panel collapses the file back to one row per action before any counting.
    - The evaluation rows that carry no enforcement fields at all are dropped before the collapse, so a facility with evaluations but no action never reaches the panel through an empty sentinel row.
    - `ENF_IDENTIFIER` is a sequence within a facility and activity location rather than an identifier of one action, so it cannot define identity on its own. The facility NJD002385730 with `ENF_ACTIVITY_LOCATION` NJ and `ENF_IDENTIFIER` 001 carries 176 distinct action dates running from 1984-03-15 to 2023-08-28, and 46,496 of the 247,819 facility, location, and identifier triples in the file carry more than one action date.
    - The key was checked for internal consistency. None of the 56,098 window actions carries two values of `ENF_TYPE` or two values of `DOCKET_NUMBER` under one key, so collapsing to the key never has to choose between competing attributes.
- **Considerations**
    - Counting raw rows instead of distinct actions would inflate every panel count by the number of evaluations, violations, and citations an action happened to touch, which is precisely the severity signal a user would want to study separately.
- **Impact**
    - The collapse takes 1,928,016 enforcement records to 365,899 actions (18.98% of the row count), so an action spans 5.27 records on average.

### Decision 3. Month Assignment ###
- **Decision**
    - An enforcement action belongs to the calendar month of its `ENF_ACTION_DATE`, the date the action was issued.
- **Details**
    - `ENF_ACTION_DATE` is populated and parseable on every enforcement record in the data, so no action is dropped for a missing or malformed date.
    - Actions dated outside 2015-2023 fall outside the panel window and are excluded.
- **Considerations**
    - The issue date was chosen over any later milestone because it is the one date every action carries and because it is the moment the agency acted. The dates that describe how an action was later closed belong to a different month than the row that would carry them, which is part of why Decision 6 leaves the disposition fields out.
- **Impact**
    - Excluded for an unparseable or blank date, 0 actions (0.00%).
    - Excluded as outside the window, 309,801 actions (84.67% of the 365,899 distinct actions).

### Decision 4. FRS Linkage ###
- **Decision**
    - Every facility-month carries `FRS_ID`, the EPA FRS `REGISTRY_ID`, so the panel can be joined to other EPA programs through a common facility identifier.
- **Details**
    - The link comes from the FRS Program Links file (`data/frs/FRS_PROGRAM_LINKS.csv`), matching the facility's RCRAInfo identifier (`HANDLER_ID`) against `PGM_SYS_ID` on the rows where `PGM_SYS_ACRNM == "RCRAINFO"`.
    - The mapping was verified to be strictly one-to-one on the RCRAINFO rows. The file holds 1,591,859 RCRAINFO rows with 1,591,859 distinct `PGM_SYS_ID` values and zero identifiers mapped to more than one `REGISTRY_ID`, so the join cannot fan out the panel.
    - The reverse direction is not injective. A registry identifier names a physical site, and a site that re-registered under RCRA carries every one of its RCRAInfo identifiers on the same `FRS_ID`. In this panel 158 registry identifiers are shared by two or more facilities, covering 323 of its 32,172 facilities (1.00 percent), and the widest case is `FRS_ID` 110000344182, carried by the four West Virginia facilities WVD005012851, WVR000523290, WVR000533646, and WVR000548222. Analyses keyed on `FRS_ID` should expect these clusters rather than assume one facility per registry identifier.
    - `FRS_ID` is empty when no RCRAINFO link exists for the facility.
- **Impact**
    - 32,163 of the 32,172 panel facilities (99.97%) link to an FRS registry identifier. The unmatched remainder is 9 facilities (0.03%) covering 972 facility-months (0.03% of the 3,474,576 panel facility-months).

### Decision 5. Facility Attributes ###
- **Decision**
    - Four facility-level attributes are taken from the facility snapshot columns that ride on the enforcement records, fixed at one value per facility, and repeated across all 108 of its months. A six-column coordinate slot block is taken from `HD_MASTER.csv` on the same terms, one block per facility repeated across its months, and it is the only thing this panel takes from the Handler master.

      | Element | Source variable | Description |
      | --- | --- | --- |
      | `CE_ACTIVITY_STATE` | `HANDLER_ACTIVITY_LOCATION` | Location of the agency regulating the facility. |
      | `CE_LOCATION_STATE` | `STATE` | State postal code where the facility is located. |
      | `CE_EPA_REGION` | `REGION` | EPA region in which the facility is located. |
      | `CE_LAND_TYPE` | `LAND_TYPE` | Current ownership status of the land on which the facility is located. |

      Coordinate slots, from `HD_MASTER.csv` rather than from `CE_MASTER.csv`, which is why they keep the `HD_` prefix. The Handler master ranks every coordinate pair available for a facility and keeps five of them; the panel carries the first two, taken from the facility's most recent handler record. A facility with a third pair keeps it in the master alone, and the run message reports how many facilities that is. The ranking, the source codes, and the reason a pair can appear in one slot and not another are documented in the [Handler master module README](../../../code/modules/02_modular_master_files/rcrainfo/README.md#coordinate-slots). The same block, under the same names, is carried by all five panels.

      | Element | Source variable | Description |
      | --- | --- | --- |
      | `HD_PREFERRED_LATITUDE` | `PREFERRED_LATITUDE` | Latitude of the pair to use for the facility, in decimal degrees. |
      | `HD_PREFERRED_LONGITUDE` | `PREFERRED_LONGITUDE` | Longitude of the pair to use for the facility, in decimal degrees. |
      | `HD_PREFERRED_COORD_SOURCE` | `PREFERRED_COORD_SOURCE` | Where that pair came from, namely `MANUAL` for a hand-placed pair, `FRS` for the Facility Registry Service pair, `HD` for the pair the facility reported, and `HD_OTHER` for a pair on another of the facility's records. |
      | `HD_ALT_LATITUDE_2` | `ALT_LATITUDE_2` | Latitude of the first pair the preference order set aside, empty where the facility has no second pair. |
      | `HD_ALT_LONGITUDE_2` | `ALT_LONGITUDE_2` | Longitude of that pair. |
      | `HD_ALT_COORD_SOURCE_2` | `ALT_COORD_SOURCE_2` | Where that pair came from, on the same four codes. |

- **Details**
    - The coordinate block is the panel's only geography beyond the state and region codes above, since the enforcement records carry no coordinates of their own. A facility whose block is empty is one that no source can place, and those facilities are listed for a manual search in `HD_COORDINATE_MANUAL_REVIEW.csv`. Slot coverage on this panel is measured on the next rebuild and recorded here then, since the block is new to this schema.
    - The value used is the value on the facility's most recent action for the three state and region attributes, and the last non-missing value for `CE_LAND_TYPE`.
    - These columns are snapshots carried on enforcement records, not a notification history, so they hold one value per facility rather than one per facility-month.
    - The attributes are drawn from the enforcement records of this panel rather than copied from the companion panels, so a facility present in more than one file can in principle carry a different snapshot in each.
- **Considerations**
    - The attributes are constant within facility in the data except for 3 facilities (0.01% of 32,172) that carry two `HANDLER_ACTIVITY_LOCATION` values across their actions, and the most-recent rule fixes those deterministically instead of leaving two competing values.
    - `LAND_TYPE` is blank on 4.88 percent of window enforcement actions (2,738 of 56,098), which is why the rule takes the last non-missing value rather than the value on the latest record.
- **Impact**
    - `CE_LAND_TYPE` remains empty for 1,821 facilities (5.66% of 32,172) whose actions never record a land type, and the other three attributes are filled for every facility.
    - `CE_ACTIVITY_STATE` differs from `CE_LOCATION_STATE` for 22 facilities (0.07%), which are facilities regulated by an agency outside the state they sit in.

### Decision 6. Elements Included from `CE_MASTER.csv` ###
- **Decision**
    - Each facility-month carries three groups of enforcement content, namely descriptive fields for the month's actions, count columns by issuing agency, and 0/1 indicator columns. All other `CE_MASTER` elements stay out of the panel.
- **Details**
    - Month-level descriptive fields, empty when the month has no action. Months holding more than one action join the multi-valued fields with semicolons in action-date order, except for the three code fields noted below as sorted.

      | Element | Source variable | Description |
      | --- | --- | --- |
      | `CE_ENF_STATE` | `ENF_ACTIVITY_LOCATION` | The state whose agency issued the action. |
      | `CE_ENF_TYPE` | `ENF_TYPE` | The month's distinct nationally-defined type codes after the recode described in Decision 7, sorted. |
      | `CE_ENF_SUBTYPE` | `ENF_TYPE` | The month's distinct codes that are not nationally defined, sorted, carried exactly as the states recorded them and unaffected by the recode. |
      | `CE_ENF_TYPE_DESC` | `ENF_TYPE_DESC` | The month's distinct type descriptions in action-date order. A defined code takes its name from the national reference table and a state-specific code takes the crosswalk's revised reading of what the state wrote. |
      | `CE_ENF_CATEGORY` | `ENF_TYPE` | The month's distinct proposed categories from the 900 block, sorted. Empty when no action in the month carries one. |
      | `CE_ENF_TYPE_NUM` | `ENF_TYPE` | Count of distinct type codes in the month as they were recorded, defined and undefined together, so the recode does not change it. |
      | `CE_DOCKET` | `DOCKET_NUMBER` | Docket numbers of the month's actions. |
      | `CE_ENF_SUBORG` | `ENF_SUBORGANIZATION` | Suborganization codes, each prefixed with its own enforcement state as STATE-SUBORG, for example IL-CD, so codes that read alike in different states stay distinct. |

    - Count and indicator columns, 0 on months with no action.

      | Element | Source rule | Description |
      | --- | --- | --- |
      | `CE_ANY_ENF`, `CE_TOTAL_ENF` | all actions | Enforcement actions issued in the month. |
      | `CE_ANY_STATE_ENF`, `CE_TOTAL_STATE_ENF` | `ENF_AGENCY == "S"` | Actions issued by a state agency. |
      | `CE_ANY_FED_ENF`, `CE_TOTAL_FED_ENF` | `ENF_AGENCY == "E"` | Actions issued by EPA. |
      | `CE_ENF_FORMAL` | recoded type in 210 through 865, or a 999 pair the crosswalk classifies as formal | Any action in the month is a formal action. |
      | `CE_ENF_INFORMAL` | recoded type in 110, 120, 130, or 140, or a 999 pair the crosswalk classifies as informal | Any action in the month is an informal action. |

    - The name `CE_ENF_SUBTYPE` reads these codes for what they are, a state's own subdivision of the national type it recodes to, and it holds the original value so the states' own coding stays recoverable beside the recoded one.
    - Elements of `CE_MASTER.csv` not included in the panel, grouped, with the rationale for exclusion.

      | Elements | Description | Rationale |
      | --- | --- | --- |
      | `HANDLER_NAME` | Facility legal name. | The facility is already keyed by `HANDLER_ID` and `FRS_ID`. |
      | Staff and counsel identifiers (`ATTORNEY`, `ENF_RESPONSIBLE_PERSON`) | Codes of the attorney assigned to the action and of the staff member responsible for it. | Staff identifiers rather than facility-month content, left out on the same rule the summary-table configs follow, and recoverable by joining the enforcement key back to `CE_MASTER.csv`. |
      | Disposition and appeal fields (`DISPOSITION_STATUS`, `DISPOSITION_STATUS_DATE`, `DISPOSITION_STATUS_DESC`, `APPEAL_INITIATED_DATE`, `APPEAL_RESOLVED_DATE`) | How an action was later closed, the date it closed, and the appeal timeline. | These describe an action's later life rather than the month it was issued, so a facility-month would carry dates falling outside its own month. They are action-level detail beneath the month grain, recoverable by joining the enforcement key back to `CE_MASTER.csv`. |
      | Consent agreement fields (`RESPONDENT_NAME`, `LEAD_AGENCY`) | Respondent named on a consent agreement or final order and the lead agency on it. | Populated only on the consent agreement and final order subset, and the respondent is a party name rather than facility-month content. |
      | `ENF_LAST_CHANGE` | Stamp of the last edit made to the enforcement record. | Describes when RCRAInfo was edited rather than what happened at the facility, so it is record machinery. |
      | Corrective action and financial assurance flags (`CA_COMPONENT`, `FA_REQUIREMENT`) | The action carries a corrective-action component, and the action carries a financial-assurance requirement. | `FA_REQUIREMENT` is coded "1" on 74 of the 1,928,016 enforcement records in `CE_MASTER`, which is 13 distinct actions in the whole file, and it is blank on 469,817 records (24.37%) against 2,822 (0.15%) for `CA_COMPONENT`. The asymmetry says the source field is incompletely populated rather than genuinely negative, so neither flag is delivered as a measure of the activity it names. |
      | Penalty fields (`PROPOSED_AMOUNT`, `FINAL_MONETARY_AMOUNT`, `PAID_AMOUNT`, `FINAL_COUNT`, `FINAL_AMOUNT`) | Proposed, final, and paid penalty amounts and the counts on a consent agreement or final order. | Populated on a small minority of actions and at a rate that differs by issuing agency, so they are left out rather than delivered as a column that is empty on most rows. |
      | Evaluation, violation, citation, information-request, and supplemental project fields | The records the enforcement key rides on in `CE_MASTER.csv`. | Documented in [`EVAL_PANEL_2015_2023_README.md`](EVAL_PANEL_2015_2023_README.md) and [`VIOL_PANEL_2015_2023_README.md`](VIOL_PANEL_2015_2023_README.md) or left to a join on the enforcement key. |

- **Considerations**
    - Enforcement responsible agency is "S" or "E" for every action in the window, so the state and federal split is exhaustive. Any other agency code, if it ever appears, would count toward neither.
    - The defined and undefined split exists because enforcement type codes are only partly national. The 37 nationally defined codes come from the RCRAInfo CME enforcement-type reference, and everything else is a state-specific code. A user comparing enforcement severity across states has to reckon with the undefined side, because the same numeric code can carry different meanings in different states. Code 312 is described as STATE AG SETTLED OUT OF COURT in CT and MA, DE NOTICE OF ADMIN PENALTY / ORDER in DE, DEP SHORT FORM CONSENT ORDER in FL, Settlement Agreement Sent to AGO in MO, and CONSENT ORDER AND AGREEMENT in PA.
    - Federal counts in 2022 are dominated by multi-site cases. Enforcement type 380 is a multi-site super consent agreement, one legal case covering many sites, and the panel records it once at each site. The single date 2022-09-28 carries 849 actions of that type at 849 distinct facilities, and type 380 totals 1,527 actions in 2022 against 46 or fewer in every year of the window other than 2021, which holds 167. A user counting federal actions over time should separate this type.
- **Impact**
    - The panel carries 56,098 actions, of which 50,242 (89.56%) were issued by a state agency and 5,856 (10.44%) by EPA.
    - Enforcement type codes on the window actions split into 40,950 carrying a nationally defined code (73.00%) and 15,148 carrying a state-specific code (27.00%), the latter spread over 77 distinct code values.
    - Blankness of the descriptive fields, measured against the 51,962 facility-months that hold at least one action, is 0 for `CE_ENF_STATE`, 4,992 (9.61%) for `CE_ENF_TYPE`, 4,117 (7.92%) for `CE_ENF_TYPE_DESC`, 19,548 (37.62%) for `CE_ENF_SUBORG`, 37,911 (72.96%) for `CE_ENF_SUBTYPE`, 44,552 (85.74%) for `CE_ENF_CATEGORY`, and 44,784 (86.19%) for `CE_DOCKET`.
    - `CE_ENF_TYPE_NUM` is 1 on 48,915 active months (94.14%), 2 on 2,890 (5.56%), 3 on 152 (0.29%), 4 on 4, and 5 on 1.
    - 3,558 of the 51,962 facility-months with actions (6.85%) hold more than one action and use the semicolon joining, and the largest is 22 actions in one month.

### Decision 7. Enforcement Type Recode and the Formal and Informal Split ###
- **Decision**
    - Each state-specific enforcement type code is matched to the nationally defined code its recorded description most closely describes, and `CE_ENF_TYPE` carries the matched code alongside the untouched original in `CE_ENF_SUBTYPE`. A pair that no defined code covers is matched to 999 and stays out of `CE_ENF_TYPE`. `CE_ENF_TYPE_DESC` carries the reference name for a defined code and the crosswalk's revised reading of the state's wording for a state-specific one. `CE_ENF_FORMAL` and `CE_ENF_INFORMAL` classify the month from the recoded codes, and `CE_ENF_CATEGORY` carries the proposed 900-block category where the crosswalk assigns one.
- **Details**
    - The matching decisions live in two reference files rather than in the panel script, so the script reads them and neither list is repeated in code. `resources/CE-Enforcement-Type.md` reproduces the RCRAInfo Nationally-Defined Values page for Enforcement Type and supplies the 37 defined codes with their names. `resources/CE-Enforcement-Type-Crosswalk.md` records, for every state-specific code and description pair that appears in `CE_MASTER`, the defined code it was matched to and the reasoning behind the match.
    - `CE_ENF_TYPE_DESC` delivers the crosswalk's revised reading of each state description rather than the raw string, so `PROPOSED CAO` reads `Proposed Corrective Action Order` and a Florida `DEP MEETING` reads `FL DEP Meeting`. The revised reading is title-cased, has its abbreviations expanded, and carries no comma, which matters because the field joins several descriptions with semicolons and a comma inside one of them would make the field ambiguous to anything that splits on it. The state's raw string is the crosswalk's join key and stays recoverable by taking `CE_ENF_SUBTYPE` back to the reference file.
    - Two national names do carry a comma, `Initial Monitoring, Analysis, Test Order` and `Final Monitoring, Analysis, Test Order` under codes 230 and 330, which `CE_MASTER` records as `INITIAL MONITORING,ANALYSIS,TEST ORDER` and `FINAL MONITORING,ANALYSIS,TEST ORDER`. They are reproduced as EPA writes them rather than reworded. The comma does not disturb the CSV, because `write_csv()` quotes any value that holds one, so the file parses back to the same 3,474,576 rows and 24 columns and the value returns intact. Two values in the panel carry a comma, one in `CE_ENF_TYPE_DESC` and one in `CE_DOCKET`, and both are quoted. No panel value contains a double quote or a line break, so the file's physical line count equals its row count plus the header. What a reader must not do is split a row on commas without honouring the quotes, and what it must not do inside a multi-valued field is split on anything other than the semicolon.
    - The crosswalk is keyed on the code and the description together, not on the code alone, because one state code carries descriptions that belong to different defined codes. Code 121 recodes to 120 when its description is VIOLATION NOTICE (VN) in IL, MI, OH, and WI, and to 140 when its description is VIOLATION LETTER - INTENT TO SUBMIT TO DEQ ENF in MT. Code 315 recodes to 310 when its description is DEP CONSENT ORDER in FL and to 305 when its description is an expedited enforcement action offer in WA.
    - A pair whose description is missing is matched to 999 regardless of its code band, because the number alone is not evidence of what the state meant by it. This is the largest single source of 999, covering 5,700 of the 7,199 window actions that stay unmatched (79.18%). The remaining unmatched actions are well described but have no national analogue, such as the internal referrals to an enforcement screening committee recorded under code 141 in TX.
    - The formal and informal split follows the code band, where 110, 120, 130, and 140 are the notification codes and every defined code from 210 upward is an order, a court filing, or a referral. It is deliberately not taken from the "Formal Action" column of the reference table, which marks the narrower set of actions that count as addressing a significant non-complier and therefore flags several unambiguously formal codes 0, including the criminal codes 710 through 740.
    - A pair matched to 999 has no code to take a class from, so the crosswalk records the class on the nine pairs whose own description settles it, and the panel reads it from there. Six are formal because the description names an order or a court filing outright, namely `STATE LEVEL ADMINISTRATIVE ORDER` under 123 and 124, `ADMINISTRATIVE ORDER` under 205, `INJUNCTIVE RELIEF` under 263, `PETITION FOR CONTEMPT` under 512, and the revocation order under 211. Three are informal because the description says so, namely `INFORMAL ACTIONS` under 101, `INFORMAL ENFORCEMENT - OTHER` under 115, and the section 3007 information request letter under 115. Every other 999 pair is left unclassified, which states that the record does not establish the class rather than that the action is neither.
    - The 37 nationally-defined codes are listed below with the class each one carries and how the window's actions reach it. "Recorded" counts the actions a state already filed under the code, and "added" counts the actions the recode brings to it from a state-specific code. A code with 0 in both columns is defined nationally but unused in the 2015-2023 window.

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

    - The proposed categories occupy the 900 block, chosen because no state code observed in `CE_MASTER` reaches 900, so a category can never collide with a recorded value. They exist because a single defined code collapses instruments a user may want apart, most of all 120 Written Informal, which absorbs the warning letters, the notices of violation, the notices of noncompliance, and the compliance advisories alike. A category never replaces the matched code, and it rides alongside it in `CE_ENF_CATEGORY`. "Matches to" names the defined codes the category's pairs resolve to, and 999 there means the category is carrying records that no defined code covers at all.

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
    - The recode changes what `CE_ENF_TYPE` means. Before it, the field held only codes the states had already recorded as national. After it, the field mixes those with codes assigned here by reading a description, so a user who needs the states' own coding should read `CE_ENF_SUBTYPE`, which is preserved for exactly that purpose.
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

### Decision 8. Balanced Grid and Zero Fill ###
- **Decision**
    - The panel is the full cross of the 32,172 facilities with all 108 months. Months without an enforcement action carry 0 in every count and indicator column and empty strings in the descriptive fields, and each `CE_ANY_*` indicator equals 1 exactly when its matching count is positive.
- **Details**
    - A 0 therefore means no action was issued in that facility-month. It is never a missing value, and the count columns are never empty.
    - The facility attributes of Decision 5 and `FRS_ID` are the only columns filled on action-free months.
    - `CE_ENF_FORMAL` and `CE_ENF_INFORMAL` are 0 on those months as well, which they share with the active months where no action is classified, so a 0 in either indicator states that no classified action of that kind was issued rather than that the month held an action of the other kind.
- **Considerations**
    - The alternative of keeping only months with actions would shrink the file by roughly a factor of sixty-five but would push the zero-versus-missing distinction onto every user. The explicit grid keeps facility-month time series directly usable for event studies and rate calculations without reconstruction, and it matches the companion panels so the three files align row for row on the facilities they share.
    - The grid does not know when a facility began or ceased to be regulated, so the zeros before a facility's first action and after its last are structural rather than observed. Analyses that need an at-risk window have to build one from the notification history in `HD_MASTER.csv`.
- **Impact**
    - 51,962 facility-months (1.50% of the 3,474,576) carry at least one enforcement action, and the remaining 3,422,614 (98.50%) are zero-filled.
    - The panel carries 56,098 actions in total, of which 9,607 active months are marked formal and 37,820 informal.

## Proposed Cross-Panel Count Fields ##
This part is a design note rather than a record of anything the panel currently carries. It sketches two count fields that would connect this panel to its companions through the linkage `CE_MASTER.csv` already holds, and it sets out the questions that have to be answered before either is built. Nothing here is implemented.

`CE_MASTER.csv` is evaluation-centred. One row is an evaluation crossed with its 3007 request, violation, enforcement action, supplemental environmental project, and citation entries, so a single evaluation fans out into as many rows as it has child records of each kind. This panel takes the enforcement slice of that structure and places it on the action date, while the evaluation panel places an evaluation on its start month and the violation panel places a violation on its determined date. The proposed fields would let a facility-month here report how many of the other panels' records are linked to it, without a user having to rejoin `CE_MASTER.csv` by hand.

- `CE_ENF_EVAL_NUM` would count the distinct evaluations that the month's enforcement actions arose from, keyed on the evaluation identity the evaluation panel uses.
- `CE_ENF_VIOL_NUM` would count the distinct violations linked to the month's enforcement actions through the evaluations they share, keyed on `VIOL_SEQ`.

### Questions to settle before building ###
- Counts must be taken on distinct child keys, not on rows. Because `CE_MASTER.csv` crosses every child kind against every other, a naive row count multiplies violations by evaluations and returns a figure that means nothing. This is the same discipline `CE_ENF_TYPE_NUM` already follows in counting distinct codes rather than rows.
- Every count sits on this panel's month, which is not the month the linked record carries. An evaluation counted by `CE_ENF_EVAL_NUM` would sit on the action's month even though the evaluation panel places it on its own start month, and the two months can fall in different cycles. The fields answer how much is linked to what happened this month here, and they must be documented as such rather than read as activity dated to the month.
- The three panels have different universes, so a linked record can point outside this panel's population. An evaluation linked to an action would be counted whether or not that evaluation's facility is itself in the evaluation panel. Whether the count should be restricted to records that also appear in the companion panel is a modelling choice that changes what the field means.
- The linkage has to be checked for completeness before either field is trusted. `CE_MASTER.csv` is built outward from evaluations, so an enforcement action that carries no evaluation key would be invisible to both fields. The share of actions with no linked evaluation should be measured first, because a large share would make them undercount in a way a user could not see.

## Institutional Context ##
The rules that shape this panel are described in the compliance and enforcement brief at [`docs/institutional_briefs/03_compliance_and_enforcement.md`](../../../docs/institutional_briefs/03_compliance_and_enforcement.md). The division of authority between EPA and the states, which is why the panel splits actions into state and federal, why enforcement type codes are only partly national, and why organizational codes keep their state prefix, is described in [`docs/institutional_briefs/04_state_authorization.md`](../../../docs/institutional_briefs/04_state_authorization.md). The identifier system behind `HANDLER_ID` and `FRS_ID` is described in [`docs/institutional_briefs/09_facility_identifiers.md`](../../../docs/institutional_briefs/09_facility_identifiers.md).
