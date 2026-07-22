# `BR_PANEL_2015_2023_UNBALANCED` Decision Record #

## Purpose ##
This document records every construction decision behind `BR_PANEL_2015_2023_UNBALANCED.csv`, built by `code/modules/03_panels/rcrainfo/02_panel_2015_2023_unbalanced.R`. Each decision states the outcome that was adopted, the details of how it is implemented, the considerations behind it where alternatives were worth weighing, and the measured impact on the data. Every count is taken from the actual input and output files, and every percentage states the baseline it is measured against. The decisions appear in the order in which they act on the data, so reading top to bottom follows the construction of the panel from the raw Biennial Report files to the final CSV.

## Construction Decisions ##

### Decision 1. Universe and Unit of Observation ###
- **Decision**
    - The panel is an unbalanced facility-year panel keyed on `HANDLER_ID` and `REPORT_CYCLE`. It covers the five Biennial Report cycles from 2015 through 2023, and a facility is included if it was recognized as an LQG and/or a TSDF in at least one of those five cycles.
- **Details**
    - The Biennial Report is filed biennially, so only odd years exist and each cycle's report describes that calendar year's activity.
    - Each facility-year represents one facility in one cycle, and a facility appears only in the cycles in which it qualifies. A facility therefore contributes between one and five facility-years.
    - Because membership requires qualification in at least one cycle rather than in all five, this panel is a strict superset of `BR_PANEL_2015_2023_BALANCED`. The balanced panel is exactly the 5,440 facilities that qualify in all five cycles, which is 27,200 facility-years or 46.94 percent of this panel.
- **Considerations**
    - The unbalanced design keeps entrants, exiters, and facilities that move across the LQG threshold between cycles. The balanced design instead holds the sample of facilities fixed so that cross-cycle comparisons are never driven by composition change. The two panels are built by the same rules so that a user can move between them and attribute any difference purely to the membership requirement.
    - Restricting to 2015-2023 keeps the panel on the modern electronic-filing era of the Biennial Report. The earlier cycles back to 2001 exist in the raw data and are counted below for scale, but they are not part of this panel.
- **Impact**
    - **Note**: A facility-year is one facility appearing in one cycle's Biennial Report file. Every percentage below states the baseline it is measured against. Distinct-facility baselines are deduplicated unions across cycles, meaning a facility that files in more than one cycle is counted only once, so the facility counts reported for individual years do not sum to the union.
    - Totals
        - All available Biennial Reports (2001-2023): 19,111,194 waste-line records, 293,822 facility-years, 100,722 distinct facilities.
        - Biennial Reports in the cycles of interest (2015-2023): 10,004,651 waste-line records (52.35%), 131,249 facility-years (44.67%), 56,405 distinct facilities (56.00%).
            - **Baseline**: all available Biennial Reports (2001-2023).
    - By year
        - `BR_REPORTING_2023.csv`: 1,769,592 waste-line records (17.69%), 24,009 facility-years (18.29%)
        - `BR_REPORTING_2021.csv`: 1,829,522 waste-line records (18.29%), 24,830 facility-years (18.92%)
        - `BR_REPORTING_2019.csv`: 2,323,177 waste-line records (23.22%), 25,707 facility-years (19.59%)
        - `BR_REPORTING_2017.csv`: 2,014,883 waste-line records (20.14%), 26,858 facility-years (20.46%)
        - `BR_REPORTING_2015.csv`: 2,067,477 waste-line records (20.67%), 29,845 facility-years (22.74%)
        - **Baseline**: Biennial Reports in the cycles of interest.
    - Panel: 57,953 facility-years (44.16%), 23,014 distinct facilities (40.80%)
        - **Baseline**: total facility-years (131,249) and distinct facilities (56,405) in the Biennial Reports of the cycles of interest. Against all available Biennial Reports (2001-2023) the panel keeps 19.72 percent of facility-years and 22.85 percent of facilities.
    - Panel facility-years by cycle, with the share of that cycle's facility-years that qualify
        - 2015: 12,312 (41.25% of 29,845)
        - 2017: 12,217 (45.49% of 26,858)
        - 2019: 11,416 (44.41% of 25,707)
        - 2021: 10,773 (43.39% of 24,830)
        - 2023: 11,235 (46.80% of 24,009)
    - Cycles qualified per panel facility
        - Qualify in 1 cycle: 10,363 (45.03%)
        - Qualify in 2 cycles: 3,127 (13.59%)
        - Qualify in 3 cycles: 2,200 (9.56%)
        - Qualify in 4 cycles: 1,884 (8.19%)
        - Qualify in 5 cycles: 5,440 (23.64%)
        - **Baseline**: the 23,014 panel facilities.

### Decision 2. LQG and TSDF Definitions ###
- **Decision**
    - Panel membership is defined from the Biennial Report's own recognition of the facility, not from the facility's notified status in RCRAInfo. A facility-year is retained only if it satisfies `BR_GENERATOR == "L"` or `BR_TSDF == 1`.
- **Details**
    - LQG. A facility-year is an LQG when any of its waste lines in `BR_REPORTING_[year].csv` carries `CALCULATED_GENERATOR_STATUS == "L"`. This is stored in the panel as `BR_GENERATOR`, which is `"L"` when the condition holds and `"N"` otherwise. `CALCULATED_GENERATOR_STATUS` takes only three values in the raw files: `L` for an LQG on the reported quantities, `N` for quantities below the LQG level, and `E` for an episodic-event filing.
    - TSDF. A facility-year is a TSDF when any of its waste lines carries `MGMT_ID_INCLUDED_IN_NBR == "Y"` or `RECV_ID_INCLUDED_IN_NBR == "Y"` (the raw Biennial Report files keep EPA's Y/N coding), meaning EPA counted the facility as a manager or receiver of hazardous waste in the published Biennial Report totals for that cycle. This is stored as `BR_TSDF`, coded 1 when the condition holds and 0 otherwise.
    - `CALCULATED_GENERATOR_STATUS` is the category EPA computes from the quantities the facility actually reported for the cycle. It is not the same as the LQG definition in `HD_MASTER.csv`, where `FED_WASTE_GENERATOR` is the category the facility notified in advance. The panel deliberately carries both, as `BR_GENERATOR` and `HD_GENERATOR`, so the two definitions can be compared on every facility-year.
    - It is therefore still possible for a facility-year to be a panel LQG while its notification history says otherwise. 6,427 facility-years (11.09% of the panel) have `BR_GENERATOR == "L"` together with an `HD_GENERATOR` that is not `"L"`, splitting into 3,207 notified as SQG (5.53%), 1,446 as VSQG (2.50%), 1,309 as non-generator (2.26%), 4 as undetermined (0.01%), and 461 with no notified category at all (0.80%). The figure rose from 8.57 percent when the Biennial Report override was withdrawn on 2026-07-21 (Decision 8); until then the override forced the two columns to agree on precisely the facility-years most likely to disagree, so the measured mismatch understated itself.
    - It is likewise still possible for a facility-year to be a panel TSDF without notified TSD activity. 3,333 facility-years have `BR_TSDF == 1` together with `HD_TSDF == "0"`, which is 5.75 percent of the panel and 56.63 percent of the 5,886 TSDF facility-years, and a further 57 facility-years (0.97 percent of the TSDF facility-years) pair the recognition with an unknown notified status (`HD_TSDF == "U"`). Recognition in the Biennial Report totals reflects waste that was actually managed or received that cycle, so it routinely reaches facilities whose standing notification does not (or no longer does) claim TSD activity.
    - The reverse mismatches also survive in the panel for facility-years that qualified through the other route. 698 facility-years (1.20%) are TSDF-only rows whose notified category is nonetheless LQG, and 1,243 (2.14%) carry notified TSD activity without Biennial Report recognition that cycle.
- **Considerations**
    - The alternative was to define membership from `HD_MASTER` notifications. That was rejected because notifications lag and drift, as the mismatch counts above show, while the Biennial Report basis matches the universe EPA itself publishes and ties membership to observed waste activity in the reporting year.
- **Impact**
    - **Baseline**: the 131,249 facility-years in the Biennial Reports of the cycles of interest.
    - Included: 57,953 facility-years (44.16%). Not included: 73,296 facility-years (55.84%).
    - Distribution of the included facility-years, with the 57,953 panel facility-years as baseline
        - LQG only: 52,067 (89.84%)
        - Both LQG and TSDF: 4,806 (8.29%)
        - TSDF only: 1,080 (1.86%)
        - Any LQG: 56,873 (98.14%); any TSDF: 5,886 (10.16%)
    - Distribution of the excluded facility-years, with the 73,296 excluded facility-years as baseline; a facility-year is excluded exactly when no waste line reaches `L` and no line carries the manager or receiver count flag
        - Episodic only (`E` present, never `L`): 28,840 (39.35%). These filed through an episodic event without reaching LQG on regular generation; all of them are still counted in the published generator counts (`GEN_ID_INCLUDED_IN_NBR == "Y"`).
        - Below the LQG level throughout (`N` only): 44,456 (60.65%). Of these, 26,259 (35.83% of the excluded) are nonetheless counted in the published generator counts, 5,968 (8.14%) filed only a Site Identification form and no waste forms at all (`BR_FORM == "XX"`), and the remaining 12,229 (16.68%) filed waste forms that EPA did not count toward any generator, manager, or receiver total.

### Decision 3. Summing Tonnages ###
- **Decision**
    - Four facility-year tonnage totals are constructed (`BR_GENERATE_TONS`, `BR_MANAGE_TONS`, `BR_SHIP_TONS`, `BR_RECEIVE_TONS`) by summing the corresponding tons column across the facility's Biennial Report waste lines for the cycle, keeping only the lines EPA counts toward the matching published total.
- **Details**
    - Each sum is restricted to lines where the corresponding inclusion flag equals `"Y"` (`GEN WASTE INCLUDED IN NBR`, `MGMT WASTE INCLUDED IN NBR`, `SHIP WASTE INCLUDED IN NBR`, `RECV WASTE INCLUDED IN NBR`).
    - This keeps the totals on the same basis as the membership flags in Decision 2 and avoids double counting, since the raw file repeats waste across generation, management, shipment, and receipt views and also carries lines EPA excludes from its published totals.
    - A total of 0 is an absence of counted activity, not a reported zero quantity. This was validated directly against `BR_REPORTING_2015` through `BR_REPORTING_2023`: every line that carries an inclusion flag has a strictly positive tonnage (across the 11,861,176 flagged lines belonging to panel facility-years there is not a single zero or missing tonnage value), so a 0 total can only arise when the facility-year has no counted lines of that type at all.
    - The totals are written as fixed-decimal strings at the raw seven-decimal precision with trailing zeros trimmed, so no binary floating-point summation noise reaches the CSV.
- **Considerations**
    - The alternative of summing every line regardless of the inclusion flags was rejected because it inflates totals with waste EPA deliberately excludes and makes the tonnages inconsistent with the published Biennial Report figures that the membership definition is anchored to.
- **Impact**
    - Decision flow per tonnage type. The first count is lines with a strictly positive tonnage value against all 10,004,651 waste-line records of 2015-2023; the second is lines entering the panel sums (inclusion flag `"Y"` on a panel facility-year) against those non-zero lines; the third is lines contributing a positive amount to the sums against the lines entering them.
        - Generation: 1,454,461 non-zero lines (14.54% of all lines); 865,050 enter the panel sums (59.48% of non-zero lines); 865,050 of 865,050 entering lines are positive (100%).
        - Management: 8,054,813 non-zero lines (80.51%); 2,358,506 enter the panel sums (29.28%); 2,358,506 of 2,358,506 are positive (100%).
        - Shipment: 1,881,411 non-zero lines (18.81%); 1,293,093 enter the panel sums (68.73%); 1,293,093 of 1,293,093 are positive (100%).
        - Receipt: 8,019,415 non-zero lines (80.16%); 7,344,527 enter the panel sums (91.58%); 7,344,527 of 7,344,527 are positive (100%).
        - Every management and receipt line EPA counts sits at a panel facility, so the panel sums capture the flagged management and receipt universe completely. For generation and shipment the flagged lines are only partly at panel facilities (865,050 of 1,288,413 flagged generation lines, 67.14%, and 1,293,093 of 1,715,882 flagged shipment lines, 75.36%); the remainder belongs to facilities EPA counts as generators or shippers below the LQG level, which Decision 2 excludes.
    - Zero totals in the panel, with the 57,953 panel facility-years as baseline; per the validation above, each of these is a facility-year with no counted lines of that type
        - `BR_GENERATE_TONS` is 0 on 189 facility-years (0.33%) and `BR_SHIP_TONS` on 459 (0.79%).
        - `BR_MANAGE_TONS` is 0 on 52,781 facility-years (91.08%) and `BR_RECEIVE_TONS` on 55,682 (96.08%). These large shares follow directly from the panel's composition, since 89.84 percent of facility-years are LQG-only facilities that neither manage nor receive waste counted in the published totals.

### Decision 4. FRS Linkage ###
- **Decision**
    - Every facility-year carries `FRS_ID`, the EPA FRS `REGISTRY_ID`, so the panel can be joined to other EPA programs through a common facility identifier.
- **Details**
    - The link comes from the FRS Program Links file (`data/frs/FRS_PROGRAM_LINKS.csv`), matching the facility's RCRAInfo identifier (`HANDLER_ID`) against `PGM_SYS_ID` on the rows where `PGM_SYS_ACRNM == "RCRAINFO"`. The mapping is one-to-one from the handler to the registry identifier, so the join cannot fan out the panel.
    - The reverse direction is not injective. A registry identifier names a physical site, and a site that re-registered under RCRA carries every one of its handler identifiers on the same `FRS_ID`. In this panel 325 registry identifiers are shared by two to four handlers, 670 handlers in all (2.91 percent of the 23,014); the widest case is `FRS_ID` 110050297717, carried by four Michigan handlers (MID000809764, MID005379797, MID005379813, MID072784036). Analyses keyed on `FRS_ID` should expect these clusters rather than assume one handler per registry identifier.
    - The mapping was verified to be strictly one-to-one on the RCRAINFO rows. The file holds 1,591,859 RCRAINFO rows with 1,591,859 distinct `PGM_SYS_ID` values and zero identifiers mapped to more than one `REGISTRY_ID`, so the join cannot fan out the panel.
    - `FRS_ID` is empty when no RCRAINFO link exists for the facility.
- **Impact**
    - 22,986 of the 23,014 panel facilities (99.88%) link to an FRS registry ID. The unmatched remainder is 28 facilities (0.12%) covering 64 facility-years (0.11% of the 57,953 panel facility-years).

### Decision 5. Elements Included from `HD_MASTER.csv` ###
- **Decision**
    - The panel attaches 32 facility attributes from the notification history in `HD_MASTER.csv`, prefixed `HD_`, five industry-code columns (`NAICS4`, `NAICS6_1` through `NAICS6_4`, governed by Decision 7), plus two constructed columns (`HD_RECORD_COUNT` and the conflict audit column of Decision 8), and a fifteen-column coordinate slot block. Each attribute is assigned one value per facility-year by class-specific dominance rules over the facility-year's calendar year, except the coordinate slots, which are facility-level and are repeated across the facility's cycles.
- **Details**
    - Included elements, grouped, with their `HD_MASTER` source variables and a short description from the data dictionary.

      Location and jurisdiction

      | Element | Source variable | Description |
      | --- | --- | --- |
      | `HD_ACTIVITY_STATE` | `ACTIVITY_LOCATION` | State where the reported activity took place. |
      | `HD_LOCATION_STATE` | `LOCATION_STATE` | State code of the facility's physical address. |
      | `HD_LOCATION_COUNTY` | `COUNTY_CODE` | FIPS code of the county in which the facility is located. |
      | `HD_EPA_REGION` | `REGION` | EPA region with which the facility is associated. |
      | `HD_LOCATION_LATITUDE` | `LOCATION_LATITUDE` | Latitude of the facility location in decimal degrees. |
      | `HD_LOCATION_LONGITUDE` | `LOCATION_LONGITUDE` | Longitude of the facility location in decimal degrees. |

      Coordinate slots, which are facility-level rather than facility-year and
      so sit outside the dominance rules of this decision. The Handler master
      ranks every coordinate pair available for a facility, and the block is
      taken whole from the facility's most recent record and repeated across its
      cycles. The ranking, the source codes, and the reason a pair can appear in
      one slot and not another are documented in the [Handler master module README](../../../code/modules/02_modular_master_files/rcrainfo/README.md#coordinate-slots).

      | Element | Source variable | Description |
      | --- | --- | --- |
      | `HD_PREFERRED_LATITUDE` | `PREFERRED_LATITUDE` | Latitude of the pair to use for the facility, in decimal degrees. |
      | `HD_PREFERRED_LONGITUDE` | `PREFERRED_LONGITUDE` | Longitude of the pair to use for the facility, in decimal degrees. |
      | `HD_PREFERRED_COORD_SOURCE` | `PREFERRED_COORD_SOURCE` | Where that pair came from, namely `MANUAL` for a hand-placed pair, `FRS` for the Facility Registry Service pair, `HD` for the pair the facility reported, and `HD_OTHER` for a pair on another of the facility's records. |
      | `HD_LATITUDE_2`-`HD_LATITUDE_5` | `LATITUDE_2`-`LATITUDE_5` | Latitudes of the pairs the preference order set aside, empty where the facility has no further pair. |
      | `HD_LONGITUDE_2`-`HD_LONGITUDE_5` | `LONGITUDE_2`-`LONGITUDE_5` | Longitudes of those pairs. |
      | `HD_COORD_SOURCE_2`-`HD_COORD_SOURCE_5` | `COORD_SOURCE_2`-`COORD_SOURCE_5` | Where each of those pairs came from, on the same four codes. |

      Industry

      | Element | Source variable | Description |
      | --- | --- | --- |
      | `NAICS4` | `NAICS_CODE`, all `NAICS_SEQ` | Four-digit prefix of the facility-year's leading industry code (rule in Decision 7). |
      | `NAICS6_1`-`NAICS6_4` | `NAICS_CODE`, all `NAICS_SEQ` | Up to four distinct industry codes of the facility-year in priority order (rule in Decision 7). |

      Generator status

      | Element | Source variable | Description |
      | --- | --- | --- |
      | `HD_GENERATOR` | `FED_WASTE_GENERATOR` | Federal regulatory generator category, determined by the quantity and/or toxicity of hazardous waste generated (raw codes 1/2/3 recoded to L/S/VS). |
      | `HD_STATE_GENERATOR` | `STATE_WASTE_GENERATOR` | Generator category under the implementing state's broader or more stringent rules. |
      | `HD_SHORT_TERM_GENERATOR` | `SHORT_TERM_GENERATOR` | Whether the generator category stems from a short-term or one-time event rather than ongoing processes. |

      TSD and recycling

      | Element | Source variable | Description |
      | --- | --- | --- |
      | `HD_TSDF` | `TSD_ACTIVITY` | Treatment, storage, or disposal of hazardous waste requiring a RCRA permit. |
      | `HD_RECYCLER_STORAGE` | `RECYCLER_ACTIVITY` | Recycles hazardous waste received from off site, with storage. |
      | `HD_RECYCLER_NONSTORAGE` | `RECYCLER_ACTIVITY_NONSTORAGE` | Recycles hazardous waste received from off site without prior storage. |

      Trade and transport

      | Element | Source variable | Description |
      | --- | --- | --- |
      | `HD_IMPORTER` | `IMPORTER_ACTIVITY` | Imports hazardous waste into the United States. |
      | `HD_RECOGNIZED_TRADER_IMPORTER` | `RECOGNIZED_TRADER_IMPORTER` | US-domiciled trader arranging imports of waste for recovery or disposal. |
      | `HD_RECOGNIZED_TRADER_EXPORTER` | `RECOGNIZED_TRADER_EXPORTER` | US-domiciled trader arranging exports of waste for recovery or disposal. |
      | `HD_SLAB_IMPORTER` | `SLAB_IMPORTER` | Importer of spent lead-acid batteries. |
      | `HD_SLAB_EXPORTER` | `SLAB_EXPORTER` | Exporter of spent lead-acid batteries. |
      | `HD_TRANSPORTER` | `TRANSPORTER` | Off-site transportation of hazardous waste. |
      | `HD_TRANSFER_FACILITY` | `TRANSFER_FACILITY` | Holds manifested hazardous waste in transit for ten days or less. |

      Exemptions and other regulated activities

      | Element | Source variable | Description |
      | --- | --- | --- |
      | `HD_ONSITE_BURNER_EXEMPTION` | `ONSITE_BURNER_EXEMPTION` | Qualifies for the small-quantity on-site burner exemption. |
      | `HD_FURNACE_EXEMPTION` | `FURNACE_EXEMPTION` | Qualifies for the smelting, melting, and refining furnace exemption. |
      | `HD_UNDERGROUND_INJECTION_ACTIVITY` | `UNDERGROUND_INJECTION_ACTIVITY` | Manages hazardous waste by underground injection. |
      | `HD_OFF_SITE_RECEIPT` | `OFF_SITE_RECEIPT` | Accepts hazardous waste from sites with a different EPA identification number. |

      Universal waste

      | Element | Source variable | Description |
      | --- | --- | --- |
      | `HD_UNIVERSAL_WASTE_LQ_HANDLER` | `LQHUW` | Large-quantity handler of universal waste. |
      | `HD_UNIVERSAL_WASTE_DEST_FACILITY` | `UNIVERSAL_WASTE_DEST_FACILITY` | Treats, disposes of, or recycles universal waste on site. |

      Used oil

      | Element | Source variable | Description |
      | --- | --- | --- |
      | `HD_USED_OIL_TRANSPORTER` | `USED_OIL_TRANSPORTER` | Transports used oil collected from more than one generator. |
      | `HD_USED_OIL_TRANSFER_FACILITY` | `USED_OIL_TRANSFER_FACILITY` | Owns or operates a used-oil transfer facility. |
      | `HD_USED_OIL_PROCESSOR` | `USED_OIL_PROCESSOR` | Processes used oil into fuels or other oil-derived products. |
      | `HD_USED_OIL_REFINER` | `USED_OIL_REFINER` | Re-refines used oil. |
      | `HD_USED_OIL_BURNER` | `USED_OIL_BURNER` | Burns off-specification used oil for energy recovery. |
      | `HD_USED_OIL_MARKET_BURNER` | `USED_OIL_MARKET_BURNER` | Directs shipments of off-specification used oil to burners. |
      | `HD_USED_OIL_SPEC_MARKETER` | `USED_OIL_SPEC_MARKETER` | First claims that used oil for energy recovery meets fuel specifications. |

      Constructed columns

      | Element | Source variable | Description |
      | --- | --- | --- |
      | `HD_RECORD_COUNT` | `SOURCE_TYPE`, `SEQ_NUMBER`, `REPORT_CYCLE`, `RECEIVE_DATE` | Number of source records (distinct `SOURCE_TYPE` and `SEQ_NUMBER` combinations) classified to the facility-year, pooled across source types. |

    - Classification year. Records are assigned to a year before any per-year computation. Source types `B` and `R` are fed by the Biennial Report and describe a report cycle rather than their submission date; 96.39 percent of `B` records arrive in the even year after their cycle. They are therefore classified by `REPORT_CYCLE` whenever it is a sane year (1980-2026), and a `B` or `R` record without a usable cycle falls back to its receive year, stepped down to the preceding odd year when even. All other source types classify by receive year. This classification drives `HD_RECORD_COUNT` and the same-year disagreements that Decision 8 resolves.
    - Coding of the activity indicators. The indicators arrive from `HD_MASTER` coded 1/0 rather than the raw Y/N, with the unknown code "U" standing where an "N" predates the flag's existence on the notification form (the recode rules live in the `02_modular_master_files` README), and the panel carries that coding through: an indicator facility-year is "1", "0", or "U".
    - Assignment rule. Every source record sets an attribute's value from its `RECEIVE_DATE` forward, forming a step function per facility, and the value in force before January 1 carries into the year. A facility that switches on December 31 therefore keeps its January-through-December value for that year. Records sharing a `RECEIVE_DATE` are first collapsed to one value per the class rules below. The year's value is then assigned by class.
        - Ranked statuses (`HD_GENERATOR`, `HD_TSDF`, `HD_STATE_GENERATOR`) keep the value holding the most days of the calendar year; day ties break by severity (L over S over VS over N over P over U for the federal category, 1 over 0 over U for TSD activity, and the federal hierarchy of Decision 8 for the state category).
        - 1/0 activity indicators (everything from `HD_SHORT_TERM_GENERATOR` through the used-oil block) are severity-dominant. A facility classified as, for example, a spent lead-acid battery importer at any point of the calendar year is one for that facility-year; 1 beats 0 regardless of days held, and a real 0 beats an unknown U.
        - Plain descriptive attributes (the location fields) keep the value holding the most days of the calendar year, and day ties keep the most recently received value. The five NAICS columns follow their own construction in Decision 7 rather than these dominance classes.
    - Two real cases illustrate why the classes differ. Facility AKD983067307 entered 2019 as an LQG under a notification received on 2016-08-22 and filed an SQG notification on 2019-09-13; LQG holds 255 days of 2019 against 110, so `HD_GENERATOR` stays `L`, whereas a last-received rule would have relabeled the entire year on the strength of a late-September filing. Facility CAD980882740 entered 2019 as a notified transporter (received 2016-02-29) and filed a non-transporter notification on 2019-01-16, so the transporter status holds only 15 days against 350; duration alone would call the year 0, but the severity rule keeps `HD_TRANSPORTER = "1"` because the facility did operate under a transporter registration during the year, and an activity performed at any time in the year is an activity of that facility-year.
    - The `HD_*` columns describe the facility's notification history and are independent of the Biennial Report filing, so they can legitimately disagree with `BR_GENERATOR` and `BR_TSDF` (Decision 2 quantifies the disagreement for the two status pairs).
    - Elements of `HD_MASTER.csv` not included in the panel, grouped, with the rationale for exclusion.

      | Elements | Description | Rationale |
      | --- | --- | --- |
      | `HANDLER_NAME`; `LOCATION_`/`MAIL_` street, city, and ZIP fields; `CONTACT_*` (name, title, address, phone, fax, email) | Facility name, full addresses, and contact-person details. | Identity and contact text with no analytic content; the facility is already keyed by `HANDLER_ID` and `FRS_ID`. |
      | `OWNER_*` and `OPERATOR_*` blocks (indicator, name, type, date, address, phone, email), `STATE_DISTRICT`, `STATE_DISTRICT_OWNER` | Owner and operator identity blocks and state legislative district. | Owner and operator rows multiply the facility records (a record can repeat once per owner and operator); ownership analysis is out of the panel's scope. |
      | `SOURCE_TYPE`, `SEQ_NUMBER`, `RECEIVE_DATE`, `REPORT_CYCLE`, `CURRENT_RECORD`, `NAICS_SEQ`, `OWNER_SEQ`, `OPERATOR_SEQ`, `HSM_SEQ_NUMBER`, `CONSOLIDATION_SEQ_NUMBER`, `EPISODIC_WASTE_SEQ` | Record keys, filing dates, and child-row sequence numbers. | Construction machinery: they build the timelines, classification years, and record counts but are not facility attributes. |
      | `ACKNOWLEDGE_FLAG`, `ACKNOWLEDGE_DATE`, `ACCESSIBILITY`, `TRIBAL_ID` | Filing-acknowledgement and processing metadata; tribal land identifier. | Administrative processing detail with no bearing on LQG or TSDF activity. |
      | `NON_NOTIFIER`, `INCLUDE_IN_NATIONAL_REPORT`, `BR_EXEMPT` | Suspected unauthorized-activity flag; inclusion flag for the published report; Biennial Report exemption claim. | Membership is already fixed by the Biennial Report recognition rules of Decision 2. |
      | `FED_WASTE_GENERATOR_OWNER`, `STATE_WASTE_GENERATOR_OWNER` | Agency that defined the generator code. | Provenance of a code, not a facility status. |
      | `MIXED_WASTE_GENERATOR`, `SUBPART_K_*` (4), `SUBPART_P_*` (3) | Mixed radioactive-waste flag (discontinued in 2019) and laboratory and pharmaceutical program flags. | Niche program flags outside the panel's LQG/TSDF focus, collected for only part of the window. |
      | `OTHER_ID`, `SAME_FACILITY`, `RELATIONSHIP`, `RELATIONSHIP_OWNER` | Alternative identifiers and their relationship to the facility. | Cross-program linkage is delegated to `FRS_ID` (Decision 4). |
      | `PUBLIC_NOTES`, `OWNER_PUBLIC_NOTES`, `OPERATOR_PUBLIC_NOTES` | Free-text notes. | Unstructured text. |

- **Considerations**
    - The alternative assignment rules were a point-in-time snapshot (the status on January 1, or the last value received in the year). The rules above were chosen because a status should reflect what the facility was for most of the reporting year, while an activity should reflect what the facility ever did during it; the two real cases in the details show each choice binding. The carry-forward step function keeps a value available in years with no new filing.
- **Impact**
    - Every panel facility-year now carries at least one classified record, because the facility's own Biennial Report filing classifies to its cycle year. `HD_RECORD_COUNT` is 0 on 0 facility-years, exactly 1 on 38,236 (65.98%), and 2 or more on 19,717 (34.02%), with the 57,953 panel facility-years as baseline.
    - Missing values remain only where the facility has no usable notification record on or before the facility-year. With the same baseline, `HD_GENERATOR`, `HD_TSDF`, and `HD_ACTIVITY_STATE` are empty on 492 facility-years (0.85%), `HD_LOCATION_STATE` on 507 (0.87%), `HD_LOCATION_COUNTY` on 514 (0.89%), `HD_EPA_REGION` on 518 (0.89%), and `HD_STATE_GENERATOR` on 697 (1.20%); the NAICS columns are covered in Decision 7.
    - The unknown code surfaces mostly through the international-shipment flags: `HD_RECOGNIZED_TRADER_IMPORTER`, `HD_RECOGNIZED_TRADER_EXPORTER`, `HD_SLAB_IMPORTER`, and `HD_SLAB_EXPORTER` are "U" on 20,963 facility-years each (36.17%), because most of their timeline predates the flags' 12/20/2016 introduction. The next largest carriers are `HD_TRANSFER_FACILITY` on 992 facility-years (1.71%), `HD_TSDF` on 594 (1.02%), `HD_RECYCLER_NONSTORAGE` on 539 (0.93%), and `HD_ONSITE_BURNER_EXEMPTION` on 532 (0.92%).
    - The coordinate fields are now filled from the EPA Facility Registry Service. The Handler master overwrites a facility's reported latitude and longitude with the FRS pair for the same registry identifier wherever the two sources can be shown to describe one place, so the panel inherits FRS geography in place of the sparse notification coordinates; the rules and their thresholds are documented in the [Handler master module README](../../../code/modules/02_modular_master_files/rcrainfo/README.md#frs-coordinates). Coverage of `HD_LOCATION_LATITUDE` and `HD_LOCATION_LONGITUDE` rises from 22,976 facility-years (39.65%) before the override to 53,747 (92.74%) after it, leaving 4,206 facility-years (7.26%) empty, which are the facilities FRS could not match and for which state and county are still the fallback.
    - The slot block reaches further than that pair, because it prefers the FRS pair wherever the facility resolves to one rather than only where the record can be shown to sit at the FRS address, and because it falls back to a pair on another of the facility's records. A facility-year is empty across the whole block only where no source can place the facility at all, and those facilities are listed for a manual search in `HD_COORDINATE_MANUAL_REVIEW.csv`. The block also carries its own provenance in `HD_PREFERRED_COORD_SOURCE`, where the earlier record-level `LOCATION_COORD_SOURCE` stayed behind in `HD_MASTER.csv`. Slot coverage and the share of facilities carrying an alternate pair are measured on the next rebuild and recorded here then, since the block is new to this schema.

### Decision 6. Elements Included from `BR_REPORTING_[year].csv` ###
- **Decision**
    - The panel keeps only the facility-level Biennial Report content, prefixed `BR_`, and collapses the waste-line detail entirely. The retained elements are the key (`HANDLER_ID`, `REPORT_CYCLE`), the membership flags (`BR_GENERATOR`, `BR_TSDF`), and the four tonnage totals of Decision 3.
- **Details**
    - The raw files are one record per waste line. Any line-level analysis can recover the full detail by joining `HANDLER_ID` and `REPORT_CYCLE` back to `BR_REPORTING_[year].csv`.
    - Elements of `BR_REPORTING_[year].csv` not included in the panel, grouped, with the rationale for exclusion.

      | Elements | Description | Rationale |
      | --- | --- | --- |
      | `ACTIVITY LOCATION`, `SOURCE TYPE`, `SEQ NUMBER`, `HZ PG`, `SUB PAGE NUM`, `BR FORM`, `MANAGEMENT LOCATION`, `LAST CHANGE` | Form and record bookkeeping: which form the line came from (GM, WR, or XX), page and sequence numbers, the on-site versus off-site marker, and the last-edit date. | Waste-line bookkeeping with no meaning at the facility-year level. |
      | `STATE`, `STATE NAME`, `REGION`, `HANDLER NAME`, `LOCATION STREET NO/1/2`, `LOCATION CITY`, `LOCATION STATE`, `LOCATION ZIP`, `COUNTY CODE`, `COUNTY NAME`, `STATE DISTRICT` | Facility identity and address snapshot on the filing. | The panel carries location from the notification history (the `HD_*` block of Decision 5) rather than the per-cycle filing snapshot. |
      | `GEN ID INCLUDED IN NBR`, `SHIP ID INCLUDED IN NBR` | Whether the facility was counted in the published generator or shipper facility counts. | Membership uses the calculated generator category and the manager and receiver count flags; these two flags mark count membership that EPA extends even to facilities below the LQG level (26,259 excluded facility-years carry the generator count flag, Decision 2). |
      | `DESCRIPTION`, `SOURCE CODE`, `FORM CODE`, `MANAGEMENT METHOD`, `FEDERAL WASTE`, `WASTEWATER`, `WASTE MIN CODE`, `WASTE CODE GROUP`, `FEDERAL WASTE CODES`, `ACUTE NONACUTE STATUS`, `WASTE GENERATION ACTIVITY`, `PRIORITY CHEMICAL`, `MANAGEMENT CATEGORY`, `WASTE PROPERTY`, `MIXED WASTE` | Waste-stream characterization: narrative description, waste codes and groupings, physical form, source process, management method, and hazard categorizations. | Line-level waste detail that the facility-year unit drops; recoverable by joining back to the raw files. |
      | `RECEIVER ID`, `RECEIVER STATE`, `RECEIVER STATE NAME`, `RECEIVER REGION`, `SHIPPER ID`, `SHIPPER STATE`, `SHIPPER STATE NAME`, `SHIPPER REGION`, `COUNTRY CODE` | Shipment counterparties and their locations. | Line-level flow geography, out of scope for a facility-year panel. |
      | `PRIMARY NAICS` | Primary NAICS code reported on the Biennial Report filing. | The panel standardizes on the notification-history codes (`NAICS4` and `NAICS6_1`-`NAICS6_4`, Decision 7) as the single industry source; the filing snapshot remains recoverable by join. |

- **Impact**
    - The five raw files hold 10,004,651 waste-line records; the panel represents the qualifying activity in 57,953 facility-years, 0.58 percent of the raw record count.

### Decision 7. Specific Element Inclusion Rule ###
- NAICS codes (`NAICS4`, `NAICS6_1`-`NAICS6_4`)
    - **Decision**
        - The panel carries five industry-code columns per facility-year, built from the facility's full NAICS listing rather than a single primary code. `NAICS6_1` through `NAICS6_4` hold up to four distinct codes in a defined priority order, and `NAICS4` holds the four-digit prefix of the facility-year's leading code.
    - **Details**
        - `NAICS_CODE` in `HD_MASTER` is multi-valued by design. A notification record can list many codes keyed by `NAICS_SEQ`, and one facility-year can legitimately carry a large set of codes at once (up to 294 distinct codes have been observed on a single facility-year in the full `HD_MASTER`).
        - Every raw code is normalized and then validated. Optional-zero codes always receive their trailing zero (33791 becomes 337910; the 573 base codes are listed in `NDV_HANDLER_NAICS_optional_zero_codes.txt`), and the retired code 517110 crosswalks to 517111 following the Census 2017-to-2022 concordance. A six-digit code must then appear in the nationally defined values table (`NDV_HANDLER_NAICS_CODES.md`, harvested from the full text of every row because roughly 54 codes and the three sector ranges sit embedded mid-description by a scrape glitch) or in an eleven-code whitelist of NAICS-2022 codes that table lacks (623110, 333310, 334510, 623210, 423620, 335220, 624410, 516120, 516210, 519290, 315120, together carrying 2,043 records); any other six-digit code is invalid and dropped. Codes shorter than six digits and the sector ranges 31-33, 44-45, and 48-49 are kept as they are, because 73 percent of the facility-years carrying one have no other code and dropping them would blank the facility-year.
        - Years are the calendar years of `RECEIVE_DATE`. Within a year, a submission is a distinct `RECEIVE_DATE` carrying at least one valid code, and its duration runs from its date to the next submission of the year, with the last submission running to December 31; windows never cross years, and dates whose codes are all invalid open no window.
        - `NAICS6_1` through `NAICS6_4` order the year's codes by `NAICS_SEQ` ascending, then submission duration descending, then the latest `RECEIVE_DATE`, then the highest `SEQ_NUMBER` for exact ties; duplicates are removed keeping the first appearance, and the first four codes fill the slots. `NAICS4` is the first four digits of the lowest-seq code on the winner submission, meaning the submission holding the longest duration with ties toward the latest date, and it stays empty when that code has fewer than four leading digits.
        - A facility-year with at least one valid code received in the year uses that year's codes only. A facility-year whose received records carry no valid code stays empty, with no carry. A facility-year with no records received in the year carries all five columns from the nearest earlier year (1980 or later) with a valid code, and stays empty when no such year exists.
        - Multiple codes are treated as a feature of the notification form rather than a disagreement, so the NAICS columns sit outside the conflict rules of Decision 8; competing codes are ordered and selected by the priority rule above, which is itself the resolution.
    - **Considerations**
        - Treating all `NAICS_SEQ` rows as competing values of one variable was rejected, since inspecting them all would flag on the order of 216,000 false-positive facility-years in the full `HD_MASTER` universe. The previous interim rule instead kept a single duration-dominant primary code (`HD_NAICS_CODE`, `NAICS_SEQ == 1` only), which exposed just 40.34 percent of the distinct facility-code pairs the panel facilities list; the five-column rule replaced it on 2026-07-13.
        - Codes are dated by receive year rather than by the report-cycle classification of Decision 5, so Biennial-Report-filed codes surface through the carry rule; this keeps the industry timeline anchored to when the information arrived.
        - Four residual choices were fixed at implementation, each a one-line change in the script. A winner submission with no seq-1 code yields `NAICS4` from its lowest seq present. Exact ties (the same seq and date carrying different codes) keep the code on the higher `SEQ_NUMBER`. Submission dates whose codes are all invalid are ignored rather than clipping the windows of valid submissions. Short codes fill slots as-is instead of being skipped.
    - **Impact**
        - `NAICS6_1` is filled on 56,349 of the 57,953 panel facility-years (97.23%). A second code exists on 7,547 facility-years (13.02%), a third on 2,053 (3.54%), and a fourth on 703 (1.21%). `NAICS4` is filled on 56,345 facility-years (97.23%), staying empty on 4 filled facility-years whose leading code has fewer than four digits.
        - 23,205 facility-years (40.04%) take their codes from records received in the year, and 33,911 (58.51%) carry them from the nearest earlier coded year, of which 30,189 (89.02% of the carried) come from the immediately preceding year. The remaining blanks split into 837 facility-years (1.44%) with no records in the year and no earlier coded year, and 767 (1.32%) whose in-year records carry no valid code.
        - The 23,014 panel facilities list 68,001 distinct facility-code pairs across all `NAICS_SEQ` positions in `HD_MASTER`; the five columns expose 29,476 of them (43.35%), against 27,434 (40.34%) under the single-code interim rule. 16,878 of the 22,993 facilities with any code (73.40%) list two or more distinct codes, and 21 facilities have no NAICS record at all.
        - The four slots truncate almost nothing: only 16 facility-years draw their codes from an in-year listing of more than four distinct codes.

### Decision 8. Data Conflicts ###
- **Decision**
    - Same-year disagreements in the facility's records are resolved by fixed class rules so that every `HD_*` attribute is single-valued. The panel carries the resolved value only; it does not carry an audit column naming the fields that disagreed.
- **Details**
    - A conflict means one `HD_*` field carries two or more distinct non-missing values among the records classified to the facility-year (classification per Decision 5: Biennial-Report-fed source types by `REPORT_CYCLE`, all others by receive year). The NAICS columns sit outside the rules entirely, because multiple industry codes on one facility are a feature of the notification form rather than a disagreement (Decision 7).
    - Because the facility's Biennial Report filing classifies to its cycle year, a conflict typically means the values filed with the Biennial Report and the values notified during the same year disagree. The rules therefore reconcile what the facility reported for the year against what it notified in the year.
    - Resolution follows the assignment classes of Decision 5. Records sharing a `RECEIVE_DATE` first collapse to one value, most severe for the ranked statuses and higher status (1 over 0 over U) for the indicators; across the year, ranked statuses resolve by duration with severity breaking day ties, 1/0 indicators resolve by severity outright, and plain attributes resolve by duration with recency ties. An unknown "U" standing beside a real value is a genuine disagreement in the records, and the real value always wins it.
    - The 1/0 indicators therefore carry a specific reading, fixed on 2026-07-21. A facility-year is coded 1 when the facility was identified in that category at any point in the calendar year, even for a single day, and 0 when it was never identified in that category during that year. Duration is deliberately not consulted, because a short stint is still a stint and the indicator answers whether the category applied at all rather than whether it applied for most of the year.
    - `U` is a third state and not a zero. It marks a facility-year whose records carry no real code for the field, a real value always beats it, and 0 must never be read as the complement of 1. The master files also recode some historical `N` entries to `U` where the `N` predates the flag, so a genuine absence can arrive as `U` rather than as 0 (see the `02_modular_master_files` README).
    - `HD_TSDF` follows this same rule. It resolved by duration until 2026-07-21, which made `HD_TSDF == 0` mean that the facility was not a TSDF for most of the year rather than never a TSDF during the year, and left it as the only 1/0 indicator running its own rule while the documentation already described it as severity-ranked.
    - The state generator category is ranked on the federal hierarchy (L over S over VS over N, with numeric state codes mapped to their federal equivalents); codes with no federal mapping rank below everything, and the raw state code is what the panel stores.
    - `HD_GENERATOR` is derived from the handler notifications alone. The value holding the most days of the calendar year wins, and severity decides only when two values hold the same number of days. It is never overwritten with `BR_GENERATOR`, so the handler-file category and the Biennial Report category stay independent measures and are free to disagree on any facility-year.
- **Considerations**
    - Earlier builds carried an audit column, `HD_CONFLICTS`, listing the fields that disagreed on each facility-year. It was removed on 2026-07-21 after every class of disagreement was worked through case by case. Each class either resolves under a rule that genuinely decides or was accepted as delivered, so the column marked resolved values as suspect without telling a user which of them to act on. No case is left unsettled, and the cost of the rules that do the settling, chiefly the facility-years a short indicator stint decides, is recorded in a working note kept outside the repository.
    - Earlier builds also overrode `HD_GENERATOR` with `BR_GENERATOR` on every facility-year where the handler records disagreed with themselves, on the reasoning that the Biennial Report is authoritative for the federal generator category. That rule was withdrawn on 2026-07-21 because it made the two columns identical on exactly the facility-years where they were most likely to differ, which removed the ability to read either one as a check on the other.
    - Resolving the 1/0 indicators by duration instead of severity was rejected. A duration rule would code a facility-year 0 whenever the category applied for less than half the year, which answers a different question than the one the indicators are built to answer and would silently discard every short stint. The cost of the severity rule is that a single day of an activity carries the whole facility-year, which is why the reading above is stated explicitly rather than left for a user to infer.
    - The alternative of dropping conflicted facility-years was rejected because conflicts concentrate in exactly the active, frequently refiling facilities the panel cares about, and after the cycle-based classification they concentrate further in facility-years where the Biennial Report and the notifications disagree, which is information worth keeping.
- **Impact**
    - The resolution rules leave every `HD_*` attribute single-valued, so the panel carries no measure of how often they fired. Their visible cost is the severity rule for the 1/0 indicators, which codes a facility-year 1 on the strength of a short stint. 2,199 of the 57,953 panel facility-years (3.79%) take a 1 from a stint shorter than the 0 it beat, across 1,453 of the 23,014 facilities (6.31%); every one of these is a 1 winning over a 0, since a real value beating an unknown is not counted here. The winning 1 held under 30 days on 275 of them and under 7 days on 55, while the 0 it displaced held a median of 305 days.
    - The fields this reaches most are `HD_UNIVERSAL_WASTE_LQ_HANDLER` on 625 facility-years, `HD_SHORT_TERM_GENERATOR` on 324, `HD_USED_OIL_BURNER` on 196, and `HD_RECYCLER_STORAGE` on 174; the pattern is a facility that files a one-off activity mid-cycle and drops it again.
    - `HD_TSDF` now follows the same rule (aligned 2026-07-21). 3,814 of the 57,953 panel facility-years (6.58%) are a TSDF, of which 120 are short stints the severity rule keeps and 95 carry `BR_TSDF == 0`, meaning the Biennial Report did not count the facility as a manager or receiver that cycle even though it notified the activity briefly.

## Extending the Tonnage Totals with e-Manifest Data ##
The four tonnage totals of Decision 3 (`BR_GENERATE_TONS`, `BR_MANAGE_TONS`, `BR_SHIP_TONS`, and `BR_RECEIVE_TONS`) are facility-year sums. Each collapses every qualifying waste line into a single number, so the panel records how much a facility generated, managed, shipped, or received in a cycle but not what the waste was or how it was treated. Decision 6 makes this loss deliberate, dropping the Biennial Report line detail that carries the waste codes, the form and source codes, and the management method, and leaving that detail recoverable only by joining back to the raw `BR_REPORTING_[year].csv` files. A user who needs the totals broken into specific waste types with their corresponding management and treatment methods therefore has to reach outside the panel, and the EPA e-Manifest tables in `data/rcrainfo/em/` are the natural source for that breakdown.

`EM_WASTE_LINE.csv` holds one row per waste line on each hazardous waste manifest, and it carries exactly the pairing the aggregated totals lose. Every line names the waste through `FEDERAL WASTE CODES` and `STATE WASTE CODES`, the downstream handling through `MANAGEMENT METHOD CODE` and `MANAGEMENT METHOD DESCRIPTION`, and the amount through `QUANTITY TONS`, with acute, non-acute, hazardous, and non-hazardous tonnage splits reported alongside it. The same rows carry the Biennial Report crosswalk fields `BR FORM CODE`, `BR SOURCE CODE`, and `BR WASTE MIN CODE`, so a manifest line can be aligned to the categories the Biennial Report itself uses. This is the dimension the panel totals discard, a shipped tonnage attached to a named waste code and to the specific method by which the receiving facility manages it.

The manifests join to the panel by handler identifier. `EM_MANIFEST.csv` keys each manifest to a `GENERATOR ID` and a `DES FACILITY ID`, both RCRAInfo handler identifiers of the same form as the panel key `HANDLER_ID`, so a panel facility can be matched on the generator side, the receiving side, or both, and `EM_WASTE_LINE.csv` attaches to its manifest on `MANIFEST TRACKING NUMBER`. The manifest dates `SHIPPED DATE` and `RECEIVED DATE` place each shipment in time, so lines can be grouped into the same odd-year cycles the panel is keyed on and then summed by waste code and management method within a facility-year.

The breakdown fits the off-site totals most directly, because a manifest is by definition an off-site movement of hazardous waste.
- `BR_SHIP_TONS` decomposes most directly, by summing a panel facility's generator-side manifest lines by waste code and method.
- `BR_RECEIVE_TONS` decomposes most directly, by summing the same facility's receiver-side manifest lines the same way.
- `BR_MANAGE_TONS` is only partly in scope, reaching the received waste a facility then manages but not the waste it manages on site.
- `BR_GENERATE_TONS` is only partly in scope, reaching generated waste that leaves under a manifest but not on-site-managed or unmanifested generation.

Two cautions keep the flag honest. The tonnage bases are not identical, since `QUANTITY TONS` on a manifest is a shipped weight per waste line while the panel totals are the Biennial Report tons that carry an inclusion flag (Decision 3), so a manifest breakdown states the composition of the shipped and received waste rather than an exact re-sum of the panel figure and should be reconciled against the panel total before use. The breakdown is also an extension that this build does not perform. The panel stops at the four aggregates by design, and the e-Manifest tables are recorded here as the route to disaggregate them, not as columns already present in `BR_PANEL_2015_2023_UNBALANCED.csv`.