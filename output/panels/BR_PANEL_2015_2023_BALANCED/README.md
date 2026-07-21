# `BR_PANEL_2015_2023_BALANCED` Decision Record #

## Purpose ##
This document records every construction decision behind `BR_PANEL_2015_2023_BALANCED.csv`, built by `code/modules/03_panels/rcrainfo/01_panel_2015_2023_balanced.R`. Each decision states the outcome that was adopted, the details of how it is implemented, the considerations behind it where alternatives were worth weighing, and the measured impact on the data. Every count is taken from the actual input and output files, and every percentage states the baseline it is measured against. The decisions appear in the order in which they act on the data, so reading top to bottom follows the construction of the panel from the raw Biennial Report files to the final CSV. The panel is the balanced counterpart of `BR_PANEL_2015_2023_UNBALANCED`, is built by the same rules apart from the membership requirement in Decision 1, and has its own decision record because the impact of every shared rule differs on the restricted sample.

## Construction Decisions ##

### Decision 1. Universe and Unit of Observation ###
- **Decision**
    - The panel is a balanced facility-year panel keyed on `HANDLER_ID` and `REPORT_CYCLE`. It covers the five Biennial Report cycles from 2015 through 2023, and a facility is included only if it was recognized as an LQG and/or a TSDF in **all five** of those cycles.
- **Details**
    - The Biennial Report is filed biennially, so only odd years exist and each cycle's report describes that calendar year's activity.
    - Each facility-year represents one facility in one cycle. Because every member qualifies in every cycle, each facility contributes exactly five facility-years (2015, 2017, 2019, 2021, 2023) and every cycle holds exactly the same 5,440 facilities.
    - The requirement is qualification per cycle, not a fixed qualification route. A facility that is an LQG in some cycles and a TSDF in others still satisfies the balance condition, and Decision 2 quantifies how often the route actually switches.
    - This panel is a strict subset of `BR_PANEL_2015_2023_UNBALANCED`, which keeps every facility qualifying in at least one cycle. Both panels are built by the same rules and share an identical column schema, so any difference between them is purely the membership requirement.
- **Considerations**
    - The balanced design holds the sample fixed across cycles, so cross-cycle comparisons are never driven by entry, exit, or facilities crossing the LQG threshold. The price is survivorship: members are continuous large-scale operators, and results from this panel describe that persistent population rather than the full LQG/TSDF universe of any single cycle. Analyses that need entrants and exiters should use the unbalanced panel.
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
    - Panel: 27,200 facility-years (20.72%), 5,440 distinct facilities (9.64%)
        - **Baseline**: total facility-years (131,249) and distinct facilities (56,405) in the Biennial Reports of the cycles of interest. Against all available Biennial Reports (2001-2023) the panel keeps 9.26 percent of facility-years and 5.40 percent of facilities.
    - Cost of the balance requirement, measured against the unbalanced panel
        - The all-five-cycles rule keeps 5,440 of the 23,014 facilities that qualify in at least one cycle (23.64%) and 27,200 of its 57,953 facility-years (46.94%). It excludes 17,574 facilities (76.36%), which are the facilities qualifying in one to four cycles.
    - Panel facilities as a share of each cycle's facility-years and of each cycle's qualifying facilities
        - 2015: 5,440 facilities are 18.23 percent of the 29,845 facility-years and 44.18 percent of the 12,312 qualifiers.
        - 2017: 20.25 percent of 26,858 facility-years, 44.53 percent of 12,217 qualifiers.
        - 2019: 21.16 percent of 25,707 facility-years, 47.65 percent of 11,416 qualifiers.
        - 2021: 21.91 percent of 24,830 facility-years, 50.50 percent of 10,773 qualifiers.
        - 2023: 22.66 percent of 24,009 facility-years, 48.42 percent of 11,235 qualifiers.

### Decision 2. LQG and TSDF Definitions ###
- **Decision**
    - Panel membership is defined from the Biennial Report's own recognition of the facility, not from the facility's notified status in RCRAInfo. A facility-year qualifies when it satisfies `BR_GENERATOR == "L"` or `BR_TSDF == 1`, and a facility enters the panel only if some qualification holds in every one of the five cycles.
- **Details**
    - LQG. A facility-year is an LQG when any of its waste lines in `BR_REPORTING_[year].csv` carries `CALCULATED_GENERATOR_STATUS == "L"`. This is stored in the panel as `BR_GENERATOR`, which is `"L"` when the condition holds and `"N"` otherwise. `CALCULATED_GENERATOR_STATUS` takes only three values in the raw files: `L` for an LQG on the reported quantities, `N` for quantities below the LQG level, and `E` for an episodic-event filing.
    - TSDF. A facility-year is a TSDF when any of its waste lines carries `MGMT_ID_INCLUDED_IN_NBR == "Y"` or `RECV_ID_INCLUDED_IN_NBR == "Y"` (the raw Biennial Report files keep EPA's Y/N coding), meaning EPA counted the facility as a manager or receiver of hazardous waste in the published Biennial Report totals for that cycle. This is stored as `BR_TSDF`, coded 1 when the condition holds and 0 otherwise.
    - `CALCULATED_GENERATOR_STATUS` is the category EPA computes from the quantities the facility actually reported for the cycle. It is not the same as the LQG definition in `HD_MASTER.csv`, where `FED_WASTE_GENERATOR` is the category the facility notified in advance. The panel deliberately carries both, as `BR_GENERATOR` and `HD_GENERATOR`, so the two definitions can be compared on every facility-year.
    - It is therefore still possible for a facility-year to be a panel LQG while its notification history says otherwise. 272 facility-years (1.00% of the panel) have `BR_GENERATOR == "L"` together with an `HD_GENERATOR` that is not `"L"`, splitting into 180 notified as SQG (0.66%), 45 as non-generator (0.17%), 39 as VSQG (0.14%), and 8 with no notified category at all (0.03%). The mismatch is an order of magnitude rarer than in the unbalanced panel (1.00% against 11.09%), because continuous filers keep their notifications current. Both figures rose when the Biennial Report override was withdrawn on 2026-07-21 (Decision 8); until then the override forced the two columns to agree on precisely the facility-years most likely to disagree, so the measured mismatch understated itself.
    - It is likewise still possible for a facility-year to be a panel TSDF without notified TSD activity. 1,968 facility-years have `BR_TSDF == 1` together with `HD_TSDF == "0"`, which is 7.24 percent of the panel and 47.83 percent of the 4,115 TSDF facility-years, and one further facility-year pairs the recognition with an unknown notified status (`HD_TSDF == "U"`). Recognition in the Biennial Report totals reflects waste that was actually managed or received that cycle, so it routinely reaches facilities whose standing notification does not (or no longer does) claim TSD activity.
    - The reverse mismatches also survive in the panel. 296 facility-years (1.09%) are TSDF-only rows whose notified category is nonetheless LQG, and 808 (2.97%) carry notified TSD activity without Biennial Report recognition that cycle.
- **Considerations**
    - The alternative was to define membership from `HD_MASTER` notifications. That was rejected because notifications lag and drift while the Biennial Report basis matches the universe EPA itself publishes and ties membership to observed waste activity in the reporting year.
    - The balance condition was deliberately placed on the union of the two routes rather than on a single route. Requiring, say, LQG status in all five cycles would silently drop facilities that migrate between roles, and the route-stability counts below show such facilities exist.
- **Impact**
    - **Baseline**: the 131,249 facility-years in the Biennial Reports of the cycles of interest.
    - Included: 27,200 facility-years (20.72%). Not included: 104,049 facility-years (79.28%).
    - Distribution of the included facility-years, with the 27,200 panel facility-years as baseline
        - LQG only: 23,085 (84.87%)
        - Both LQG and TSDF: 3,731 (13.72%)
        - TSDF only: 384 (1.41%)
        - Any LQG: 26,816 (98.59%); any TSDF: 4,115 (15.13%)
    - Distribution of the excluded facility-years, with the 104,049 excluded facility-years as baseline
        - Qualifying facility-years at facilities that do not qualify in all five cycles: 30,753 (29.56%). These are LQG and/or TSDF facility-years that only the unbalanced panel keeps.
        - Episodic only (`E` present, never `L`, no TSD recognition): 28,840 (27.72%).
        - Below the LQG level throughout (`N` only, no TSD recognition): 44,456 (42.73%).
    - Route stability, with the 5,440 panel facilities as baseline
        - 5,295 facilities (97.33%) are LQGs in all five cycles, of which 4,280 (78.68%) are never a TSDF and 1,015 (18.66%) are a TSDF in at least one cycle.
        - 571 facilities (10.50%) are TSDFs in all five cycles, and 1,160 (21.32%) are a TSDF in at least one cycle.
        - 145 facilities (2.67%) are not an LQG in every cycle and stay in the panel through their TSDF recognition; 31 of them (0.57%) hold neither route in all five cycles and qualify only because the two routes alternate. Dropping the union rule would remove these facilities.
    - Qualifying facilities by cycle
        - LQG facilities are nearly constant across cycles (5,357 in 2015, 5,362 in 2017, 5,370 in 2019, 5,363 in 2021, 5,364 in 2023).
        - TSDF facilities fall monotonically from 935 in 2015 to 720 in 2023, a 23.0 percent decline; the TSDF side of the panel thins even within the fixed sample.

### Decision 3. Summing Tonnages ###
- **Decision**
    - Four facility-year tonnage totals are constructed (`BR_GENERATE_TONS`, `BR_MANAGE_TONS`, `BR_SHIP_TONS`, `BR_RECEIVE_TONS`) by summing the corresponding tons column across the facility's Biennial Report waste lines for the cycle, keeping only the lines EPA counts toward the matching published total.
- **Details**
    - Each sum is restricted to lines where the corresponding inclusion flag equals `"Y"` (`GEN WASTE INCLUDED IN NBR`, `MGMT WASTE INCLUDED IN NBR`, `SHIP WASTE INCLUDED IN NBR`, `RECV WASTE INCLUDED IN NBR`).
    - This keeps the totals on the same basis as the membership flags in Decision 2 and avoids double counting, since the raw file repeats waste across generation, management, shipment, and receipt views and also carries lines EPA excludes from its published totals.
    - A total of 0 is an absence of counted activity, not a reported zero quantity. This was validated directly against `BR_REPORTING_2015` through `BR_REPORTING_2023`: every line that carries an inclusion flag on a panel facility-year has a strictly positive tonnage (across the 10,325,514 flagged lines belonging to panel facility-years there is not a single zero or missing tonnage value), so a 0 total can only arise when the facility-year has no counted lines of that type at all.
    - The totals are written as fixed-decimal strings at the raw seven-decimal precision with trailing zeros trimmed, so no binary floating-point summation noise reaches the CSV.
- **Considerations**
    - The alternative of summing every line regardless of the inclusion flags was rejected because it inflates totals with waste EPA deliberately excludes and makes the tonnages inconsistent with the published Biennial Report figures that the membership definition is anchored to.
- **Impact**
    - Decision flow per tonnage type. The first count is lines with a strictly positive tonnage value against all 10,004,651 waste-line records of 2015-2023; the second is lines entering the panel sums (inclusion flag `"Y"` on a panel facility-year) against those non-zero lines; the third is lines contributing a positive amount to the sums against the lines entering them.
        - Generation: 1,454,461 non-zero lines (14.54% of all lines); 553,748 enter the panel sums (38.07% of non-zero lines); 553,748 of 553,748 entering lines are positive (100%).
        - Management: 8,054,813 non-zero lines (80.51%); 2,188,122 enter the panel sums (27.17%); 2,188,122 of 2,188,122 are positive (100%).
        - Shipment: 1,881,411 non-zero lines (18.81%); 945,866 enter the panel sums (50.27%); 945,866 of 945,866 are positive (100%).
        - Receipt: 8,019,415 non-zero lines (80.16%); 6,637,778 enter the panel sums (82.77%); 6,637,778 of 6,637,778 are positive (100%).
        - Even on the restricted sample the panel captures most of the flagged management and receipt universe: its facilities hold 92.78 percent of all management lines EPA counts (2,188,122 of 2,358,506) and 90.38 percent of all counted receipt lines (6,637,778 of 7,344,527), against 42.98 percent of counted generation lines and 55.12 percent of counted shipment lines.
    - Zero totals in the panel, with the 27,200 panel facility-years as baseline; per the validation above, each of these is a facility-year with no counted lines of that type
        - `BR_GENERATE_TONS` is 0 on 138 facility-years (0.51%) and `BR_SHIP_TONS` on 164 (0.60%).
        - `BR_MANAGE_TONS` is 0 on 23,689 facility-years (87.09%) and `BR_RECEIVE_TONS` on 25,344 (93.18%). These large shares follow directly from the panel's composition, since 84.87 percent of facility-years are LQG-only facilities that neither manage nor receive waste counted in the published totals.

### Decision 4. FRS Linkage ###
- **Decision**
    - Every facility-year carries `FRS_ID`, the EPA FRS `REGISTRY_ID`, so the panel can be joined to other EPA programs through a common facility identifier.
- **Details**
    - The link comes from the FRS Program Links file (`data/frs/FRS_PROGRAM_LINKS.csv`), matching the facility's RCRAInfo identifier (`HANDLER_ID`) against `PGM_SYS_ID` on the rows where `PGM_SYS_ACRNM == "RCRAINFO"`.
    - The mapping was verified to be strictly one-to-one on the RCRAINFO rows. The file holds 1,591,859 RCRAINFO rows with 1,591,859 distinct `PGM_SYS_ID` values and zero identifiers mapped to more than one `REGISTRY_ID`, so the join cannot fan out the panel.
    - One-to-one runs from the handler to the registry identifier only; the reverse direction is not injective. A registry identifier names a physical site, and a site that re-registered under RCRA carries every one of its handler identifiers on the same `FRS_ID`. In this panel 37 registry identifiers are shared by two handlers each, 74 handlers in all (1.36 percent of the 5,440). A representative case is `FRS_ID` 110000332220, carried by both PAD000780171 and PAD001604693. Analyses keyed on `FRS_ID` should expect these clusters rather than assume one handler per registry identifier.
    - `FRS_ID` is empty when no RCRAINFO link exists for the facility.
- **Impact**
    - 5,436 of the 5,440 panel facilities (99.93%) link to an FRS registry ID. The unmatched remainder is 4 facilities (0.07%) covering 20 facility-years (0.07% of the 27,200 panel facility-years).
    - 5,399 distinct `FRS_ID` values cover the 5,436 linked facilities, the 37 shared registry identifiers above accounting for the difference.

### Decision 5. Elements Included from `HD_MASTER.csv` ###
- **Decision**
    - The panel attaches 32 facility attributes from the notification history in `HD_MASTER.csv`, prefixed `HD_`, five industry-code columns (`NAICS4`, `NAICS6_1` through `NAICS6_4`, governed by Decision 7), plus two constructed columns (`HD_RECORD_COUNT` and the conflict audit column of Decision 8). Each attribute is assigned one value per facility-year by class-specific dominance rules over the facility-year's calendar year.
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
    - Two real cases from this panel illustrate why the classes differ. Facility FLR000070409 entered 2019 as an LQG under a notification received on 2018-03-02 and filed an SQG notification on 2019-10-01; LQG holds 273 days of 2019 against 92, so `HD_GENERATOR` stays `L`, whereas a last-received rule would have relabeled the entire year on the strength of an October filing. Facility CAD980882740 entered 2019 as a notified transporter (received 2016-02-29) and filed a non-transporter notification on 2019-01-16, so the transporter status holds only 15 days against 350; duration alone would call the year 0, but the severity rule keeps `HD_TRANSPORTER = "1"` because the facility did operate under a transporter registration during the year, and an activity performed at any time in the year is an activity of that facility-year.
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
    - Every panel facility-year carries at least one classified record, because the facility's own Biennial Report filing classifies to its cycle year. `HD_RECORD_COUNT` is 0 on 0 facility-years, exactly 1 on 18,237 (67.05%), and 2 or more on 8,963 (32.95%), with the 27,200 panel facility-years as baseline.
    - Missing values are nearly absent, because every member has a long filing history. With the same baseline, `HD_GENERATOR`, `HD_TSDF`, and the activity-state, state, county, and region fields are empty on 8 facility-years (0.03%) and `HD_STATE_GENERATOR` on 16 (0.06%). The corresponding shares in the unbalanced panel run 0.85 to 1.20 percent.
    - The unknown code surfaces mostly through the international-shipment flags: `HD_RECOGNIZED_TRADER_IMPORTER`, `HD_RECOGNIZED_TRADER_EXPORTER`, `HD_SLAB_IMPORTER`, and `HD_SLAB_EXPORTER` are "U" on 8,900 facility-years each (32.72%), because most of their timeline predates the flags' 12/20/2016 introduction. The next largest carriers are `HD_RECYCLER_NONSTORAGE` on 232 facility-years (0.85%), `HD_TRANSFER_FACILITY` on 33 (0.12%), and `HD_TSDF` on 17 (0.06%).
    - The coordinate fields are the exception and carry a real caveat. `HD_LOCATION_LATITUDE` and `HD_LOCATION_LONGITUDE` are empty on 15,724 facility-years (57.81%), because most notification records simply do not populate coordinates. Users needing geography should prefer state and county, or geocode through `FRS_ID`.

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
      | `GEN ID INCLUDED IN NBR`, `SHIP ID INCLUDED IN NBR` | Whether the facility was counted in the published generator or shipper facility counts. | Membership uses the calculated generator category and the manager and receiver count flags; these two flags mark count membership that EPA extends even to facilities below the LQG level (Decision 2). |
      | `DESCRIPTION`, `SOURCE CODE`, `FORM CODE`, `MANAGEMENT METHOD`, `FEDERAL WASTE`, `WASTEWATER`, `WASTE MIN CODE`, `WASTE CODE GROUP`, `FEDERAL WASTE CODES`, `ACUTE NONACUTE STATUS`, `WASTE GENERATION ACTIVITY`, `PRIORITY CHEMICAL`, `MANAGEMENT CATEGORY`, `WASTE PROPERTY`, `MIXED WASTE` | Waste-stream characterization: narrative description, waste codes and groupings, physical form, source process, management method, and hazard categorizations. | Line-level waste detail that the facility-year unit drops; recoverable by joining back to the raw files. |
      | `RECEIVER ID`, `RECEIVER STATE`, `RECEIVER STATE NAME`, `RECEIVER REGION`, `SHIPPER ID`, `SHIPPER STATE`, `SHIPPER STATE NAME`, `SHIPPER REGION`, `COUNTRY CODE` | Shipment counterparties and their locations. | Line-level flow geography, out of scope for a facility-year panel. |
      | `PRIMARY NAICS` | Primary NAICS code reported on the Biennial Report filing. | The panel standardizes on the notification-history codes (`NAICS4` and `NAICS6_1`-`NAICS6_4`, Decision 7) as the single industry source; the filing snapshot remains recoverable by join. |

- **Impact**
    - The five raw files hold 10,004,651 waste-line records; the panel represents the qualifying activity in 27,200 facility-years, 0.27 percent of the raw record count.

### Decision 7. Specific Element Inclusion Rule ###
- NAICS codes (`NAICS4`, `NAICS6_1`-`NAICS6_4`)
    - **Decision**
        - The panel carries five industry-code columns per facility-year, built from the facility's full NAICS listing rather than a single primary code. `NAICS6_1` through `NAICS6_4` hold up to four distinct codes in a defined priority order, and `NAICS4` holds the four-digit prefix of the facility-year's leading code.
    - **Details**
        - `NAICS_CODE` in `HD_MASTER` is multi-valued by design. A notification record can list many codes keyed by `NAICS_SEQ`, and one facility-year can legitimately carry a large set of codes at once (up to 294 distinct codes have been observed on a single facility-year in the full `HD_MASTER`).
        - Every raw code is normalized and then validated. Optional-zero codes always receive their trailing zero (33791 becomes 337910; the 573 base codes are listed in `NDV_HANDLER_NAICS_optional_zero_codes.txt`), and the retired code 517110 crosswalks to 517111 following the Census 2017-to-2022 concordance. A six-digit code must then appear in the nationally defined values table (`NDV_HANDLER_NAICS_CODES.md`, harvested from the full text of every row because roughly 54 codes and the three sector ranges sit embedded mid-description by a scrape glitch) or in an eleven-code whitelist of NAICS-2022 codes that table lacks (623110, 333310, 334510, 623210, 423620, 335220, 624410, 516120, 516210, 519290, 315120); any other six-digit code is invalid and dropped. Codes shorter than six digits and the sector ranges 31-33, 44-45, and 48-49 are kept as they are, because 73 percent of the facility-years carrying one have no other code and dropping them would blank the facility-year.
        - Years are the calendar years of `RECEIVE_DATE`. Within a year, a submission is a distinct `RECEIVE_DATE` carrying at least one valid code, and its duration runs from its date to the next submission of the year, with the last submission running to December 31; windows never cross years, and dates whose codes are all invalid open no window.
        - `NAICS6_1` through `NAICS6_4` order the year's codes by `NAICS_SEQ` ascending, then submission duration descending, then the latest `RECEIVE_DATE`, then the highest `SEQ_NUMBER` for exact ties; duplicates are removed keeping the first appearance, and the first four codes fill the slots. `NAICS4` is the first four digits of the lowest-seq code on the winner submission, meaning the submission holding the longest duration with ties toward the latest date, and it stays empty when that code has fewer than four leading digits.
        - A facility-year with at least one valid code received in the year uses that year's codes only. A facility-year whose received records carry no valid code stays empty, with no carry. A facility-year with no records received in the year carries all five columns from the nearest earlier year (1980 or later) with a valid code, and stays empty when no such year exists.
        - Multiple codes are treated as a feature of the notification form rather than a disagreement, so the NAICS columns sit outside the conflict rules of Decision 8; competing codes are ordered and selected by the priority rule above, which is itself the resolution.
    - **Considerations**
        - Treating all `NAICS_SEQ` rows as competing values of one variable was rejected, since inspecting them all would flag on the order of 216,000 false-positive facility-years in the full `HD_MASTER` universe. The previous interim rule instead kept a single duration-dominant primary code (`HD_NAICS_CODE`, `NAICS_SEQ == 1` only); the five-column rule replaced it on 2026-07-13.
        - Codes are dated by receive year rather than by the report-cycle classification of Decision 5, so Biennial-Report-filed codes surface through the carry rule; this keeps the industry timeline anchored to when the information arrived.
        - Four residual choices were fixed at implementation, each a one-line change in the script. A winner submission with no seq-1 code yields `NAICS4` from its lowest seq present. Exact ties (the same seq and date carrying different codes) keep the code on the higher `SEQ_NUMBER`. Submission dates whose codes are all invalid are ignored rather than clipping the windows of valid submissions. Short codes fill slots as-is instead of being skipped.
    - **Impact**
        - `NAICS6_1` is filled on 26,818 of the 27,200 panel facility-years (98.60%). A second code exists on 4,202 facility-years (15.45%), a third on 1,188 (4.37%), and a fourth on 393 (1.44%). `NAICS4` is filled on the same 26,818 facility-years (98.60%); no facility-year in this panel has a leading code too short to derive it.
        - 11,085 facility-years (40.75%) take their codes from records received in the year, and 16,099 (59.19%) carry them from the nearest earlier coded year, of which 15,690 (97.46% of the carried) come from the immediately preceding year. The remaining blanks split into 16 facility-years (0.06%) with no records in the year and no earlier coded year, and 366 (1.35%) whose in-year records carry no valid code.
        - Every one of the 5,440 panel facilities has at least one NAICS record, and 4,525 (83.18%) list two or more distinct codes. The facilities list 20,930 distinct facility-code pairs across all `NAICS_SEQ` positions in `HD_MASTER`; the five columns expose 8,468 of them (40.46%).

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
    - The state generator category is ranked on the federal hierarchy (L over S over VS over N, with numeric state codes mapped to their federal equivalents); codes with no federal mapping rank below everything, and the raw state code is what the panel stores. The non-convertible codes were checked against the real cases rather than left to the rule alone: the panel's two 2015 occurrences (KYR000029207 filing D alongside S, and LAR000053413 filing 7 alongside N) were manually reviewed and confirmed to the convertible partner, exactly what the ranking yields.
    - `HD_GENERATOR` is derived from the handler notifications alone. The value holding the most days of the calendar year wins, and severity decides only when two values hold the same number of days. It is never overwritten with `BR_GENERATOR`, so the handler-file category and the Biennial Report category stay independent measures and are free to disagree on any facility-year.
- **Considerations**
    - Earlier builds carried an audit column, `HD_CONFLICTS`, listing the fields that disagreed on each facility-year. It was removed on 2026-07-21 after every class of disagreement was worked through case by case. Each class either resolves under a rule that genuinely decides or was accepted as delivered, so the column marked resolved values as suspect without telling a user which of them to act on. The residual cases that no rule settles are recorded in a working note kept outside the repository.
    - Earlier builds also overrode `HD_GENERATOR` with `BR_GENERATOR` on every facility-year where the handler records disagreed with themselves, on the reasoning that the Biennial Report is authoritative for the federal generator category. That rule was withdrawn on 2026-07-21 because it made the two columns identical on exactly the facility-years where they were most likely to differ, which removed the ability to read either one as a check on the other.
    - Resolving the 1/0 indicators by duration instead of severity was rejected. A duration rule would code a facility-year 0 whenever the category applied for less than half the year, which answers a different question than the one the indicators are built to answer and would silently discard every short stint. The cost of the severity rule is that a single day of an activity carries the whole facility-year, which is why the reading above is stated explicitly rather than left for a user to infer.
    - The alternative of dropping conflicted facility-years was rejected because conflicts concentrate in exactly the active, frequently refiling facilities the panel cares about, and after the cycle-based classification they concentrate further in facility-years where the Biennial Report and the notifications disagree, which is information worth keeping.
- **Impact**
    - 3,415 of the 27,200 panel facility-years (12.56%) carry at least one conflict, covering 1,927 of the 5,440 facilities (35.42%). A small share of these are unknown-versus-value disagreements created by the master file's "U" recodes.
    - The most conflicted fields, with the 27,200 panel facility-years as baseline, are `HD_STATE_GENERATOR` on 906 facility-years (3.33%), `HD_LOCATION_LONGITUDE` on 897 (3.30%), `HD_LOCATION_LATITUDE` on 888 (3.26%), `HD_UNIVERSAL_WASTE_LQ_HANDLER` on 769 (2.83%), `HD_OFF_SITE_RECEIPT` on 538 (1.98%), and `HD_TSDF` on 393 (1.44%); every other field is below 1.00 percent.
    - `HD_GENERATOR` conflicts on only 167 facility-years (0.61%), against 4.34 percent in the unbalanced panel: the stable membership files Biennial Reports that agree with its notifications on the federal generator category far more often. The Biennial Report override applies to all 167 flagged facility-years; on those facility-years `HD_GENERATOR` equals `BR_GENERATOR` by construction.

## Extending the Tonnage Totals with e-Manifest Data ##
The four tonnage totals of Decision 3 (`BR_GENERATE_TONS`, `BR_MANAGE_TONS`, `BR_SHIP_TONS`, and `BR_RECEIVE_TONS`) are facility-year sums. Each collapses every qualifying waste line into a single number, so the panel records how much a facility generated, managed, shipped, or received in a cycle but not what the waste was or how it was treated. Decision 6 makes this loss deliberate, dropping the Biennial Report line detail that carries the waste codes, the form and source codes, and the management method, and leaving that detail recoverable only by joining back to the raw `BR_REPORTING_[year].csv` files. A user who needs the totals broken into specific waste types with their corresponding management and treatment methods therefore has to reach outside the panel, and the EPA e-Manifest tables in `data/rcrainfo/em/` are the natural source for that breakdown.

`EM_WASTE_LINE.csv` holds one row per waste line on each hazardous waste manifest, and it carries exactly the pairing the aggregated totals lose. Every line names the waste through `FEDERAL WASTE CODES` and `STATE WASTE CODES`, the downstream handling through `MANAGEMENT METHOD CODE` and `MANAGEMENT METHOD DESCRIPTION`, and the amount through `QUANTITY TONS`, with acute, non-acute, hazardous, and non-hazardous tonnage splits reported alongside it. The same rows carry the Biennial Report crosswalk fields `BR FORM CODE`, `BR SOURCE CODE`, and `BR WASTE MIN CODE`, so a manifest line can be aligned to the categories the Biennial Report itself uses. This is the dimension the panel totals discard, a shipped tonnage attached to a named waste code and to the specific method by which the receiving facility manages it.

The manifests join to the panel by handler identifier. `EM_MANIFEST.csv` keys each manifest to a `GENERATOR ID` and a `DES FACILITY ID`, both RCRAInfo handler identifiers of the same form as the panel key `HANDLER_ID`, so a panel facility can be matched on the generator side, the receiving side, or both, and `EM_WASTE_LINE.csv` attaches to its manifest on `MANIFEST TRACKING NUMBER`. The manifest dates `SHIPPED DATE` and `RECEIVED DATE` place each shipment in time, so lines can be grouped into the same odd-year cycles the panel is keyed on and then summed by waste code and management method within a facility-year.

The breakdown fits the off-site totals most directly, because a manifest is by definition an off-site movement of hazardous waste.
- `BR_SHIP_TONS` decomposes most directly, by summing a panel facility's generator-side manifest lines by waste code and method.
- `BR_RECEIVE_TONS` decomposes most directly, by summing the same facility's receiver-side manifest lines the same way.
- `BR_MANAGE_TONS` is only partly in scope, reaching the received waste a facility then manages but not the waste it manages on site.
- `BR_GENERATE_TONS` is only partly in scope, reaching generated waste that leaves under a manifest but not on-site-managed or unmanifested generation.

Beware: The tonnage bases are not identical, since `QUANTITY TONS` on a manifest is a shipped weight per waste line while the panel totals are the Biennial Report tons that carry an inclusion flag (Decision 3), so a manifest breakdown states the composition of the shipped and received waste rather than an exact re-sum of the panel figure and should be reconciled against the panel total before use. The breakdown is also an extension that this build does not perform. The panel stops at the four aggregates by design, and the e-Manifest tables are recorded here as the route to disaggregate them, not as columns already present in `BR_PANEL_2015_2023_BALANCED.csv`.
