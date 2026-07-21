# Enforcement Type Defined-Undefined Crosswalk

Every RCRAInfo enforcement type code that appears in `CE_MASTER` but is not one of the 37 nationally-defined codes is mapped here to the defined code its description most closely matches. The reference for the defined codes is the RCRAInfo Nationally-Defined Values page for Enforcement Type, reproduced in `rcrainfo_enforcement_types.md`.

The undefined codes were extracted from `output/modular_master_files/CE_MASTER.csv` on 2026-07-20. There are 126 undefined codes carrying 274 distinct code-and-description pairs, and every pair is mapped below. Counts are distinct enforcement actions, where an action is one combination of the five-column RCRAInfo enforcement key (`HANDLER_ID`, `ENF_ACTIVITY_LOCATION`, `ENF_IDENTIFIER`, `ENF_ACTION_DATE`, `ENF_AGENCY`), so they are lower than raw `CE_MASTER` row counts, which repeat each action across its evaluation, violation, citation and SEP rows.

## How each mapping was made

The description of the action decides the mapping, not the numeric neighbourhood of the code. Where the description is silent on whether an order is initial or final, the code band is used to break the tie, so a description reading only `COMMISSIONER'S ORDER` under code 211 resolves to the initial code 210. Where the description actively contradicts its band, the description still wins and the pair is left at 999, which is why `STATE LEVEL ADMINISTRATIVE ORDER` under the informal codes 123 and 124 is not forced onto an informal code.

A pair is mapped to 999 when no defined code covers it. The largest single reason is an absent description, and by rule every pair whose description is missing maps to 999 regardless of its code band, because the code number alone is not evidence of what the state meant by it. The other reason is that the action is real and well described but has no national analogue, such as an internal referral to an enforcement screening committee.

## Formal and informal

A mapped line carries `CE_ENF_FORMAL` or `CE_ENF_INFORMAL`, the two facility-month indicators the enforcement panel derives from the recoded type. The informal types are the four notification codes 110, 120, 130, and 140, and every other defined code from 210 upward is a formal action, so a line matched to one of those codes takes its flag from the code alone.

A line matched to 999 has no code to take a flag from, but its description sometimes settles the question on its own, and where it does the flag is recorded anyway. That is the one place in this file where the description carries information the mapped code cannot. Nine pairs qualify. Six are formal because the description names an order or a court filing outright, namely `STATE LEVEL ADMINISTRATIVE ORDER` under 123 and 124, `ADMINISTRATIVE ORDER` under 205, `INJUNCTIVE RELIEF` under 263, `PETITION FOR CONTEMPT` under 512, and the revocation order under 211. Three are informal because the description says so, namely `INFORMAL ACTIONS` under 101, `INFORMAL ENFORCEMENT - OTHER` under 115, and the section 3007 information request letter under 115.

Every other line matched to 999 carries neither flag, which is a statement that the record does not establish the class rather than a statement that the action is neither. Most of those lines have no description at all.

This split follows the code band and the wording of the definitions. It is deliberately not taken from the reference table's `Formal Action` column, which marks the narrower set of actions that count as addressing a significant non-complier and therefore flags several unambiguously formal codes 0, including the criminal codes 710 through 740.

## Revised descriptions

Descriptions as `CE_MASTER` records them are inconsistent in case, heavily abbreviated, and sometimes misspelled, so each line that carries a description also carries a `REVISED` reading of it. The original stays first on the line because it is the join key; the revised form is for reading and for any display the panel eventually wants.

Four rules produce it. Book title case is applied, leaving the short conjunctions, articles, and prepositions lowercase unless they open or close the name. A proper noun is kept, and a state environmental department keeps its own abbreviation with the postal code of its state in front, so a Florida `DEP MEETING` becomes `FL DEP Meeting`. Abbreviations that carry no institutional meaning are expanded, so `PROPOSED CAO` becomes `Proposed Corrective Action Order`. Where a description spells a name out and then repeats it as an abbreviation in parentheses, the parentheses are dropped whole and the abbreviation is recorded in the table below instead, so `Letter of Warning (LOW)` becomes `Letter of Warning`.

A revised description never contains a comma, because a line already uses commas to separate its own fields and a comma inside the name would make the line ambiguous to anything that splits on it. Where the original used a comma to hold two parts of a name apart, the revised form uses a spaced hyphen instead, so `UNILATERAL ORDER, NO PENALTIES` reads `Unilateral Order - No Penalties`.

A standalone state abbreviation is expanded to the state name, so `DE NOTICE OF VIOLATION (NOV)` becomes `Delaware Notice of Violation`. The postal code survives only in front of an agency. Abbreviations that the national reference table itself uses are kept, which is why `3008(a)`, `3008(h)`, `CA`, and `CA/FO` still appear. Obvious misspellings in the source are corrected, so `CONSECT ORDER` reads `Consent Order` and `FORGIVEABLE` reads `Forgivable`, and the original spelling is still on the line ahead of it.

| Abbreviation | Expansion | Treatment |
| ------------ | --------- | --------- |
| `ADMIN`, `ADMN` | Administrative | expanded |
| `AG` | Attorney General | expanded |
| `AGO` | Attorney General's Office | expanded |
| `APO` | Administrative Penalty Order | expanded |
| `ASST` | Assistance | expanded |
| `CAO` | Corrective Action Order | expanded |
| `CAPSB` | Compliance Assurance and Program Support Branch, an EPA Region 2 unit | expanded |
| `CONCIL.` | Conciliation | expanded |
| `DE`, `MD` standing alone | Delaware, Maryland | expanded to the state name |
| `ENF.` | Enforcement | expanded |
| `EQB` | Environmental Quality Board | expanded |
| `EQC` | Environmental Quality Commission | expanded |
| `ESC` | Enforcement Screening Committee | expanded |
| `HEAR OFF` | Hearing Officer | expanded |
| `IPCB` | Illinois Pollution Control Board | expanded |
| `LOV` | Letter of Violation | dropped from the parentheses |
| `LOW` | Letter of Warning | dropped from the parentheses |
| `LTR` | Letter | expanded |
| `EEAO` | Expedited Enforcement Action Offer | dropped from the parentheses |
| `NOC` | Notice of Noncompliance | expanded, on the reading that matches the code's match to 903 |
| `NOD` | Notice of Deficiency | dropped from the parentheses |
| `NOV` | Notice of Violation | expanded, and dropped where it sat in parentheses |
| `NOVCO` | Notice of Violation Consent Order | expanded |
| `NOVP` | Notice of Violation with Penalty | dropped from the parentheses |
| `PAO` | Proposed Agreed Order | dropped from the parentheses |
| `RTC` | Return to Compliance | expanded |
| `SFO` | Stipulated Final Order | expanded |
| `SUPERF/REMEDIA` | Superfund or Remediation | expanded |
| `VN` | Violation Notice | dropped from the parentheses |
| `3008(a)`, `3008(h)`, `CA`, `CA/FO`, `RCRA` | statutory and national reference terms | kept, since the national reference table uses them |
| `FL DEP`, `MT DEQ`, `NC DENR`, `WV DEP` | state environmental departments | kept, with the state postal code in front |
| `CP/CO`, `DCC`, `NOPA` | not established from the data | kept as recorded, since expanding them would be a guess |

## Proposed new categories

Several instruments appear tens of thousands of times across many states and are collapsed onto a single defined code, usually 120 Written Informal, which erases the distinction between them. Others are frequent but are not enforcement actions at all and currently sit at 999 with no way to tell them apart from genuinely unclassifiable records. The codes below are proposed to carry those distinctions. The 900 block is used because no state code observed in `CE_MASTER` reaches 900, so the new codes cannot collide with an existing value.

These categories sit alongside the defined-code mapping rather than replacing it. A line mapped to 120 with `NEW = 902` is still a written informal action in the national scheme and can be aggregated as one, but it can also be separated from the warning letters and the notices of noncompliance that share that code.

| New code | Category | Definition | Undefined codes | Actions |
| -------- | -------- | ---------- | --------------- | ------- |
| 901 | Warning Letter | A written informal notice, titled a warning letter or letter of warning, that puts the site on notice of observed violations without asserting a formal position. |  5 | 11,335 |
| 902 | Notice of Violation | A written informal notice, titled a notice of violation, violation notice, or letter of violation, that names the specific violations found. |  6 |  8,038 |
| 903 | Notice of Noncompliance | A written informal notice, titled a notice of noncompliance, that states the site is out of compliance without necessarily itemising violations. |  5 |  9,670 |
| 904 | Compliance Advisory or Assistance Letter | A written communication whose purpose is advisory or assistance rather than accusatory, including compliance advisories and compliance communication letters. |  5 |  3,449 |
| 905 | Enforcement Meeting or Conference | An oral proceeding held with the site, including show cause meetings, enforcement conferences, administrative conferences, and settlement meetings. |  8 |  4,683 |
| 906 | Internal Referral to Enforcement | A referral that moves a case from the inspection or compliance unit to the enforcement unit of the same agency, with no instrument served on the site. |  5 |  3,101 |
| 907 | Proposed or Draft Order | An order that has been drafted, proposed, or transmitted for negotiation but not yet issued or executed. |  5 |  2,118 |
| 908 | Case Closeout or Action Withdrawn | An entry that closes, drops, terminates, revokes, releases, or otherwise withdraws a prior enforcement action, or records a return to compliance. | 12 |    957 |
| 909 | Administrative Workflow Milestone | An internal case-management event such as assignment, document receipt, or order revision, which is not an enforcement action against the site. |  6 |  1,635 |
| 910 | Appeal, Hearing, or Remand | A step in the respondent's challenge to an action, including appeals filed, hearings requested, and matters remanded. |  5 |    430 |
| 911 | Stipulated Penalty Demand | A demand for penalties already stipulated in an existing order, which enforces a prior action rather than initiating a new one. |  4 |     84 |
| 912 | Notice of Deficiency | A written informal notice that a submission or a condition is deficient, distinct from a notice naming a regulatory violation. |  3 |     61 |

## Mapping

* 085
   * <no description> = 999, n = 1
* 086
   * <no description> = 999, n = 11
* 095
   * <no description> = 999, n = 75
   * DECISION TO END CASE-NO FURTHER ACTION = 999, n = 3, NEW = 908, REVISED = Decision to End Case - No Further Action
* 101
   * Assigned to Enforcement = 999, n = 290, NEW = 909, REVISED = Assigned to Enforcement
   * INFORMAL ACTIONS = 999, n = 283, CE_ENF_INFORMAL = 1, REVISED = Informal Actions
   * FIELD INSPECTION REPORT = 250, n = 22, CE_ENF_FORMAL = 1, REVISED = Field Inspection Report
   * <no description> = 999, n = 10
* 102
   * <no description> = 999, n = 39
* 104
   * <no description> = 999, n = 5
* 105
   * <no description> = 999, n = 3,393
* 108
   * FIELD NOC = 120, n = 11, CE_ENF_INFORMAL = 1, NEW = 903, REVISED = Field Notice of Noncompliance
* 111
   * INFORMAL WRITTEN NOTIFICATION = 120, n = 1,397, CE_ENF_INFORMAL = 1, REVISED = Informal Written Notification
   * ENFORCEMENT CONFERENCE = 110, n = 167, CE_ENF_INFORMAL = 1, NEW = 905, REVISED = Enforcement Conference
   * Penalty Assessment Team Meeting = 110, n = 56, CE_ENF_INFORMAL = 1, NEW = 905, REVISED = Penalty Assessment Team Meeting
   * <no description> = 999, n = 22
   * COMPLIANCE ASST RECOMMEND LTR = 120, n = 12, CE_ENF_INFORMAL = 1, NEW = 904, REVISED = Compliance Assistance Recommendation Letter
   * VERBAL INFORMAL = 110, n = 7, CE_ENF_INFORMAL = 1, REVISED = Verbal Informal
* 112
   * <no description> = 999, n = 232
   * Bureau Director Decision Date = 999, n = 57, NEW = 909, REVISED = Bureau Director Decision Date
   * Release of Notice of Violation = 999, n = 9, NEW = 908, REVISED = Release of Notice of Violation
* 114
   * <no description> = 999, n = 1,114
   * Compliance Communication Letter = 120, n = 899, CE_ENF_INFORMAL = 1, NEW = 904, REVISED = Compliance Communication Letter
* 115
   * DEP MEETING = 110, n = 3,408, CE_ENF_INFORMAL = 1, NEW = 905, REVISED = FL DEP Meeting
   * <no description> = 999, n = 2,372
   * CAPSB compliance assurance action letter = 120, n = 102, CE_ENF_INFORMAL = 1, NEW = 904, REVISED = Compliance Assurance and Program Support Branch Compliance Assurance Action Letter
   * WARNING LETTER = 120, n = 29, CE_ENF_INFORMAL = 1, NEW = 901, REVISED = Warning Letter
   * INFORMAL ENFORCEMENT - OTHER = 999, n = 28, CE_ENF_INFORMAL = 1, REVISED = Informal Enforcement - Other
   * INFORMATION REQUEST LETTER(3007) = 999, n = 7, CE_ENF_INFORMAL = 1, REVISED = 3007 Information Request Letter
* 116
   * <no description> = 999, n = 4
   * VOLUNTARY CLEAN-UP = 999, n = 1, REVISED = Voluntary Cleanup
* 117
   * <no description> = 999, n = 362
* 118
   * NOTICE OF DEFICIENCY = 120, n = 54, CE_ENF_INFORMAL = 1, NEW = 912, REVISED = Notice of Deficiency
* 119
   * INSPECTOR FACT FINDING LETTER - Warning letter = 120, n = 1,939, CE_ENF_INFORMAL = 1, NEW = 901, REVISED = Inspector Fact Finding Letter - Warning Letter
* 121
   * VIOLATION NOTICE (VN) = 120, n = 3,418, CE_ENF_INFORMAL = 1, NEW = 902, REVISED = Violation Notice
   * NOTICE OF NONCOMPLIANCE = 120, n = 2,765, CE_ENF_INFORMAL = 1, NEW = 903, REVISED = Notice of Noncompliance
   * Letter of Warning (LOW) = 120, n = 2,740, CE_ENF_INFORMAL = 1, NEW = 901, REVISED = Letter of Warning
   * WRITTEN INFORMAL = 120, n = 823, CE_ENF_INFORMAL = 1, REVISED = Written Informal
   * <no description> = 999, n = 797
   * SITE COMPLAINT = 120, n = 423, CE_ENF_INFORMAL = 1, NEW = 902, REVISED = Site Complaint
   * FIELD NOTICE OF VIOLATION = 120, n = 309, CE_ENF_INFORMAL = 1, NEW = 902, REVISED = Field Notice of Violation
   * VIOLATION LETTER - INTENT TO SUBMIT TO DEQ ENF = 140, n = 98, CE_ENF_INFORMAL = 1, REVISED = Violation Letter - Intent to Submit to MT DEQ Enforcement
   * DE LETTER OF WARNING (LOW) = 120, n = 92, CE_ENF_INFORMAL = 1, NEW = 901, REVISED = Delaware Letter of Warning
   * CENTRAL OFFICE NOV LETTER = 120, n = 21, CE_ENF_INFORMAL = 1, NEW = 902, REVISED = Central Office Notice of Violation Letter
   * STATE WRITTEN INFORMAL = 120, n = 2, CE_ENF_INFORMAL = 1, REVISED = State Written Informal
* 122
   * <no description> = 999, n = 3,399
   * Notice of Violation (NOV) = 120, n = 1,475, CE_ENF_INFORMAL = 1, NEW = 902, REVISED = Notice of Violation
   * DE NOTICE OF VIOLATION (NOV) = 120, n = 942, CE_ENF_INFORMAL = 1, NEW = 902, REVISED = Delaware Notice of Violation
   * Referral to Enforcement = 999, n = 466, NEW = 906, REVISED = Referral to Enforcement
   * Notice of Violation = 120, n = 165, CE_ENF_INFORMAL = 1, NEW = 902, REVISED = Notice of Violation
   * NOTICE OF INTENT TO PURSUE LEGAL ACTION = 140, n = 122, CE_ENF_INFORMAL = 1, REVISED = Notice of Intent to Pursue Legal Action
   * WRITTEN COMPLAINT = 120, n = 115, CE_ENF_INFORMAL = 1, NEW = 902, REVISED = Written Complaint
   * APPEAL = 999, n = 17, NEW = 910, REVISED = Appeal
   * Letter of Violation (LOV) = 120, n = 16, CE_ENF_INFORMAL = 1, NEW = 902, REVISED = Letter of Violation
   * Demand Notice = 999, n = 10, NEW = 911, REVISED = Demand Notice
   * Expedited Citation Informal Penalty Action = 250, n = 2, CE_ENF_FORMAL = 1, REVISED = Expedited Citation Informal Penalty Action
* 123
   * DEP NON-COMPLIANCE LETTER = 120, n = 2,501, CE_ENF_INFORMAL = 1, NEW = 903, REVISED = FL DEP Noncompliance Letter
   * TEN DAY LETTER = 120, n = 413, CE_ENF_INFORMAL = 1, NEW = 902, REVISED = Ten Day Letter
   * Termination of Enforcement Order = 999, n = 126, NEW = 908, REVISED = Termination of Enforcement Order
   * MARYLAND NOTICE OF VIOLATION = 120, n = 62, CE_ENF_INFORMAL = 1, NEW = 902, REVISED = Maryland Notice of Violation
   * <no description> = 999, n = 56
   * STATE LEVEL ADMINISTRATIVE ORDER = 999, n = 8, CE_ENF_FORMAL = 1, REVISED = State Level Administrative Order
   * DROP ACTION = 999, n = 6, NEW = 908, REVISED = Drop Action
   * DE NOTICE OF DEFICIENCY (NOD) = 120, n = 5, CE_ENF_INFORMAL = 1, NEW = 912, REVISED = Delaware Notice of Deficiency
   * District Referral to Enforcement = 999, n = 5, NEW = 906, REVISED = District Referral to Enforcement
* 124
   * NOTICE OF NONCOMPLIANCE LETTER = 120, n = 2,266, CE_ENF_INFORMAL = 1, NEW = 903, REVISED = Notice of Noncompliance Letter
   * NOTICE OF NONCOMPLIANCE = 120, n = 2,126, CE_ENF_INFORMAL = 1, NEW = 903, REVISED = Notice of Noncompliance
   * CASE CLOSED- INFORMAL RTC, DEREFERRAL OR OTHER = 999, n = 25, NEW = 908, REVISED = Case Closed - Informal Return to Compliance - Dereferral or Other
   * DROP ENFORCEMENT ACTION = 999, n = 14, NEW = 908, REVISED = Drop Enforcement Action
   * ADMIN. REVIEW = 999, n = 1, NEW = 909, REVISED = Administrative Review
   * RCRA ACTION DROPPED- NO VIOLATION = 999, n = 1, NEW = 908, REVISED = RCRA Action Dropped - No Violation
   * STATE LEVEL ADMINISTRATIVE ORDER = 999, n = 1, CE_ENF_FORMAL = 1, REVISED = State Level Administrative Order
* 125
   * DEP WARNING LETTER = 120, n = 5,812, CE_ENF_INFORMAL = 1, NEW = 901, REVISED = FL DEP Warning Letter
   * <no description> = 999, n = 5,276
   * ENF. ACTION REQUEST = 999, n = 821, NEW = 906, REVISED = Enforcement Action Request
   * Director-Division Warning Letter = 120, n = 332, CE_ENF_INFORMAL = 1, NEW = 901, REVISED = Director Division Warning Letter
   * PRE-ENFORCEMENT NOTICE = 140, n = 216, CE_ENF_INFORMAL = 1, REVISED = Pre-Enforcement Notice
   * NOTICE OF VIOLATION = 120, n = 110, CE_ENF_INFORMAL = 1, NEW = 902, REVISED = Notice of Violation
   * NOV/INITIAL STATE ADMIN CONSENT/COMPLIANCE ORDER = 210, n = 52, CE_ENF_FORMAL = 1, REVISED = Notice of Violation or Initial State Administrative Consent or Compliance Order
   * Memorandum of Understanding = 999, n = 1, REVISED = Memorandum of Understanding
* 126
   * WARNING LETTER = 120, n = 391, CE_ENF_INFORMAL = 1, NEW = 901, REVISED = Warning Letter
   * NOTICE OF VIOLATION = 120, n = 152, CE_ENF_INFORMAL = 1, NEW = 902, REVISED = Notice of Violation
   * NOTICE OF VIOLATION LETTER = 120, n = 145, CE_ENF_INFORMAL = 1, NEW = 902, REVISED = Notice of Violation Letter
   * PROPOSED CONSENT ADMIN ORDER = 210, n = 9, CE_ENF_FORMAL = 1, NEW = 907, REVISED = Proposed Consent Administrative Order
* 127
   * V3 Conversion Compliance Advisory = 999, n = 685, NEW = 904, REVISED = Version 3 Conversion Compliance Advisory
   * SHOW CAUSE MEETING = 110, n = 419, CE_ENF_INFORMAL = 1, NEW = 905, REVISED = Show Cause Meeting
   * FACILITY APPEALED = 999, n = 300, NEW = 910, REVISED = Facility Appealed
   * <no description> = 999, n = 28
   * Final Penalty Letter = 999, n = 3, REVISED = Final Penalty Letter
* 128
   * <no description> = 999, n = 399
   * SHOW CAUSE MEETING - DECLINED = 999, n = 18, NEW = 905, REVISED = Show Cause Meeting - Declined
* 129
   * <no description> = 999, n = 1
* 131
   * BACK IN COMPLIANCE LTR = 999, n = 468, NEW = 908, REVISED = Back in Compliance Letter
   * CASE IN PROGRESS = 999, n = 1, NEW = 909, REVISED = Case in Progress
* 132
   * DOCUMENT RECEIVED = 999, n = 1,214, NEW = 909, REVISED = Document Received
   * <no description> = 999, n = 1
* 135
   * No Further Action = 999, n = 166, NEW = 908, REVISED = No Further Action
* 141
   * REFERRAL TO ESC ENFORCEMENT SCREEN COMM. = 999, n = 933, NEW = 906, REVISED = Referral to Enforcement Screening Committee
   * Call-in Meeting-Settlement Meeting = 110, n = 29, CE_ENF_INFORMAL = 1, NEW = 905, REVISED = Call-In Meeting - Settlement Meeting
   * <no description> = 999, n = 5
   * LETTER OF INTENT TO INITIATE ENFORCEMENT ACTION = 140, n = 5, CE_ENF_INFORMAL = 1, REVISED = Letter of Intent to Initiate Enforcement Action
* 142
   * MEETING FOLLOWING NOPA VERBAL OR LETTER = 110, n = 6, CE_ENF_INFORMAL = 1, NEW = 905, REVISED = Meeting Following NOPA - Verbal or Letter
* 145
   * <no description> = 999, n = 1,323
   * DETERMINED NOT TO BE A VIOLATION = 999, n = 30, NEW = 908, REVISED = Determined Not to Be a Violation
* 146
   * REMANDED FOR HEARING = 999, n = 94, NEW = 910, REVISED = Remanded for Hearing
   * <no description> = 999, n = 2
* 147
   * <no description> = 999, n = 365
* 149
   * PROPOSED CAO = 240, n = 367, CE_ENF_FORMAL = 1, NEW = 907, REVISED = Proposed Corrective Action Order
* 150
   * Notice of Deficiency = 120, n = 2, CE_ENF_INFORMAL = 1, NEW = 912, REVISED = Notice of Deficiency
* 151
   * REFERRAL TO ENFORCEMENT = 999, n = 876, NEW = 906, REVISED = Referral to Enforcement
* 161
   * <no description> = 999, n = 2,597
   * ADMINISTRATIVE CONFERENCE (ENFORCEMENT CONFERENCE HELD WITH FACILITY) = 110, n = 531, CE_ENF_INFORMAL = 1, NEW = 905, REVISED = Administrative Conference Held With Facility
* 166
   * <no description> = 999, n = 87
* 171
   * <no description> = 999, n = 62
* 175
   * COMPLIANCE ADVISORY = 120, n = 1,751, CE_ENF_INFORMAL = 1, NEW = 904, REVISED = Compliance Advisory
* 201
   * Penalty negotiation letter = 999, n = 72, REVISED = Penalty Negotiation Letter
   * Expedited Citation Formal Penalty Action = 250, n = 16, CE_ENF_FORMAL = 1, REVISED = Expedited Citation Formal Penalty Action
   * Expedited Citation Informal Penalty Action = 250, n = 2, CE_ENF_FORMAL = 1, REVISED = Expedited Citation Informal Penalty Action
* 205
   * ADMINISTRATIVE ORDER = 999, n = 2, CE_ENF_FORMAL = 1, REVISED = Administrative Order
* 208
   * INITIAL PROPOSED CONSENT ORDER = 210, n = 57, CE_ENF_FORMAL = 1, NEW = 907, REVISED = Initial Proposed Consent Order
* 209
   * REVISED PROPOSED CONSENT ORDER = 210, n = 28, CE_ENF_FORMAL = 1, NEW = 907, REVISED = Revised Proposed Consent Order
   * <no description> = 999, n = 25
* 211
   * FORGIVEABLE ADMN PENALTY ORDER(APO) = 210, n = 375, CE_ENF_FORMAL = 1, REVISED = Forgivable Administrative Penalty Order
   * UNILATERAL ORDER, NO PENALTIES = 210, n = 252, CE_ENF_FORMAL = 1, REVISED = Unilateral Order - No Penalties
   * COMPLAINT AND ORDER = 210, n = 54, CE_ENF_FORMAL = 1, REVISED = Complaint and Order
   * REVOKED OR DISMISSED INITIAL FORMAL 210 COMPLIANCE ORDER = 999, n = 28, NEW = 908, REVISED = Revoked or Dismissed Initial Formal 210 Compliance Order
   * COMMISSIONER'S ORDER - INITIAL = 210, n = 24, CE_ENF_FORMAL = 1, REVISED = Commissioner's Order - Initial
   * Administrative Order Appeals Process = 999, n = 8, NEW = 910, REVISED = Administrative Order Appeals Process
   * <no description> = 999, n = 5
   * COMMISSIONER'S ORDER = 210, n = 1, CE_ENF_FORMAL = 1, REVISED = Commissioner's Order
   * INITIAL PENALTY ASSESSMENT [SIGNED AND FILED] = 210, n = 1, CE_ENF_FORMAL = 1, REVISED = Initial Penalty Assessment - Signed and Filed
   * REVOCATION ORDER-REVOKE OR DISMISS INITIAL/UNILATERAL ORDERS (CODE 210) = 999, n = 1, CE_ENF_FORMAL = 1, NEW = 908, REVISED = Revocation Order to Revoke or Dismiss Initial or Unilateral Orders Under Code 210
* 212
   * NON-FORGIVEABLE APO = 210, n = 132, CE_ENF_FORMAL = 1, REVISED = Non-Forgivable Administrative Penalty Order
   * Revision of Enforcement Order = 999, n = 72, NEW = 909, REVISED = Revision of Enforcement Order
   * <no description> = 999, n = 23
   * NO DESCRIPTION AVAILABLE = 999, n = 7, REVISED = No Description Available
* 213
   * INITIAL 3008(A) CP/CO ORDER = 210, n = 575, CE_ENF_FORMAL = 1, REVISED = Initial 3008(a) CP/CO Order
   * FORGIVEABLE & NON-FORGIVEABLE APO = 210, n = 470, CE_ENF_FORMAL = 1, REVISED = Forgivable and Non-Forgivable Administrative Penalty Order
   * <no description> = 999, n = 49
* 214
   * <no description> = 999, n = 161
   * NOVCO WITH PENALTY = 210, n = 119, CE_ENF_FORMAL = 1, REVISED = Notice of Violation Consent Order With Penalty
   * IPCB ADMINISTRATIVE COMPLAINT = 210, n = 51, CE_ENF_FORMAL = 1, REVISED = Illinois Pollution Control Board Administrative Complaint
* 215
   * DEP NOTICE OF VIOLATION (NOV) = 120, n = 272, CE_ENF_INFORMAL = 1, NEW = 902, REVISED = FL DEP Notice of Violation
   * <no description> = 999, n = 137
   * LATE FEE & PENALTY FOR NOT PAYING ANNUAL FEE, 3008(a) (COMPLIANCE ORDER) = 210, n = 18, CE_ENF_FORMAL = 1, REVISED = Late Fee and Penalty for Not Paying Annual Fee - 3008(a) Compliance Order
   * INITIAL MULTIMEDIA 3008(A) = 210, n = 13, CE_ENF_FORMAL = 1, REVISED = Initial Multi-Media 3008(a)
   * NOVCO WITHOUT PENALTY = 210, n = 1, CE_ENF_FORMAL = 1, REVISED = Notice of Violation Consent Order Without Penalty
* 216
   * <no description> = 999, n = 110
* 217
   * PROPOSED AGREED ORDER (PAO) SENT = 210, n = 1,657, CE_ENF_FORMAL = 1, NEW = 907, REVISED = Proposed Agreed Order Sent
   * <no description> = 999, n = 71
* 219
   * FACILITY ENFORCEMENT MEETING 3008(a) (COMPLIANCE SETTLEMENT) = 110, n = 49, CE_ENF_INFORMAL = 1, NEW = 905, REVISED = Facility Enforcement Meeting 3008(a) for Compliance Settlement
* 221
   * <no description> = 999, n = 4
* 222
   * ANNUAL FEE, COMPLIANCE ORDER INCLUDES PENALTY, LATE FEE & ANNUAL FEE (STATE) = 210, n = 1, CE_ENF_FORMAL = 1, REVISED = State Annual Fee Compliance Order Including Penalty - Late Fee - Annual Fee
* 224
   * <no description> = 999, n = 2
* 225
   * SEAL ORDER = 220, n = 1, CE_ENF_FORMAL = 1, REVISED = Seal Order
* 226
   * <no description> = 999, n = 1
* 231
   * <no description> = 999, n = 7
* 241
   * FIELD FAST TRACK ORDER INITIATION = 250, n = 31, CE_ENF_FORMAL = 1, REVISED = Field Fast Track Order Initiation
* 251
   * FIELD CITATION - MD NOV = 250, n = 196, CE_ENF_FORMAL = 1, REVISED = Field Citation - Maryland Notice of Violation
   * INITIAL EXPEDITED ENFORCEMENT OFFER = 305, n = 65, CE_ENF_FORMAL = 1, REVISED = Initial Expedited Enforcement Offer
   * DEMAND FOR STIPULATED PENALTIES = 999, n = 23, NEW = 911, REVISED = Demand for Stipulated Penalties
   * EXPEDITED ENFORCEMENT OFFER = 305, n = 15, CE_ENF_FORMAL = 1, REVISED = Expedited Enforcement Offer
   * FIELD COMPLIANCE ORDER = 250, n = 2, CE_ENF_FORMAL = 1, REVISED = Field Compliance Order
* 252
   * <no description> = 999, n = 1
* 255
   * Notice of Hearing and Complaint = 210, n = 3, CE_ENF_FORMAL = 1, REVISED = Notice of Hearing and Complaint
* 263
   * INJUNCTIVE RELIEF = 999, n = 29, CE_ENF_FORMAL = 1, REVISED = Injunctive Relief
* 266
   * <no description> = 999, n = 1
* 267
   * <no description> = 999, n = 1
* 301
   * NOTICE OF VIOLATION WITH PENALTY (NOVP) = 210, n = 26, CE_ENF_FORMAL = 1, REVISED = Notice of Violation With Penalty
   * RELEASE OF VIOLATION = 999, n = 24, NEW = 908, REVISED = Release of Violation
   * RELEASE OF NOTICE OF VIOLATION = 999, n = 23, NEW = 908, REVISED = Release of Notice of Violation
* 309
   * <no description> = 999, n = 18
* 311
   * CONSENT ASSESSMENT OF CIVIL PENALTY = 310, n = 242, CE_ENF_FORMAL = 1, REVISED = Consent Assessment of Civil Penalty
   * STATE CONSENT/COMPLIANCE ORDER 3008(A) = 310, n = 190, CE_ENF_FORMAL = 1, REVISED = State Consent or Compliance Order 3008(a)
   * <no description> = 999, n = 168
   * CONSENT ORDER, NO PENALTIES = 310, n = 128, CE_ENF_FORMAL = 1, REVISED = Consent Order - No Penalties
   * STATE COMPLIANCE ORDER 3008(A) = 310, n = 64, CE_ENF_FORMAL = 1, REVISED = State Compliance Order 3008(a)
   * FINAL PENALTY SETTLEMENT ORDER = 310, n = 41, CE_ENF_FORMAL = 1, REVISED = Final Penalty Settlement Order
   * CONSENT AGREEMENT = 310, n = 36, CE_ENF_FORMAL = 1, REVISED = Consent Agreement
   * DE SECRETARYS ORDER = 310, n = 13, CE_ENF_FORMAL = 1, REVISED = Delaware Secretary's Order
   * COMMISIONER'S ORDER - FINAL = 310, n = 5, CE_ENF_FORMAL = 1, REVISED = Commissioner's Order - Final
   * REVOKED OR DISMISSED INITIAL FORMAL 310 CONSECT ORDER = 999, n = 4, NEW = 908, REVISED = Revoked or Dismissed Initial Formal 310 Consent Order
* 312
   * DEP SHORT FORM CONSENT ORDER = 310, n = 2,201, CE_ENF_FORMAL = 1, REVISED = FL DEP Short Form Consent Order
   * <no description> = 999, n = 153
   * DE NOTICE OF ADMIN PENALTY / ORDER = 310, n = 50, CE_ENF_FORMAL = 1, REVISED = Delaware Notice of Administrative Penalty or Order
   * Settlement Agreement Sent to AGO = 310, n = 44, CE_ENF_FORMAL = 1, REVISED = Settlement Agreement Sent to Attorney General's Office
   * CONSENT ORDER AND AGREEMENT = 310, n = 16, CE_ENF_FORMAL = 1, REVISED = Consent Order and Agreement
   * STATE AG SETTLED OUT OF COURT = 610, n = 15, CE_ENF_FORMAL = 1, REVISED = State Attorney General Settled Out of Court
* 313
   * <no description> = 999, n = 212
   * EXECUTED STIPULATION AGREEMENT = 310, n = 199, CE_ENF_FORMAL = 1, REVISED = Executed Stipulation Agreement
   * Demand for Stipulated Penalty = 999, n = 6, NEW = 911, REVISED = Demand for Stipulated Penalty
   * DE NOTICE OF CONCIL. PROCEEDINGS / ORDER = 310, n = 4, CE_ENF_FORMAL = 1, REVISED = Delaware Notice of Conciliation Proceedings or Order
* 314
   * FINAL 3008(A) SFO ORDER = 310, n = 381, CE_ENF_FORMAL = 1, REVISED = Final 3008(a) Stipulated Final Order
   * IPCB FINAL ADMINISTRATIVE ORDER = 310, n = 73, CE_ENF_FORMAL = 1, REVISED = Illinois Pollution Control Board Final Administrative Order
   * DE CEASE AND DESIST ORDER = 310, n = 5, CE_ENF_FORMAL = 1, REVISED = Delaware Cease and Desist Order
* 315
   * DEP CONSENT ORDER = 310, n = 960, CE_ENF_FORMAL = 1, REVISED = FL DEP Consent Order
   * STIPULATED PENALTY CALL-IN = 999, n = 45, NEW = 911, REVISED = Stipulated Penalty Call-In
   * UNILATERAL ORDER = 310, n = 41, CE_ENF_FORMAL = 1, REVISED = Unilateral Order
   * Agreed order for penalty. (EEAO - Expedited Enforcement Action Offer). = 305, n = 28, CE_ENF_FORMAL = 1, REVISED = Agreed Order for Penalty
   * FINAL 3008(A) DEFAULT ORDER = 310, n = 24, CE_ENF_FORMAL = 1, REVISED = Final 3008(a) Default Order
   * <no description> = 999, n = 11
   * FINAL MULTIMEDIA 3008(A) = 310, n = 11, CE_ENF_FORMAL = 1, REVISED = Final Multi-Media 3008(a)
   * ADMINISTRATIVE ORDER = 310, n = 5, CE_ENF_FORMAL = 1, REVISED = Administrative Order
   * Expedited settlement of a penalty (EEAO - Expedited Enforcement Action Offer) = 305, n = 3, CE_ENF_FORMAL = 1, REVISED = Expedited Settlement of a Penalty
* 316
   * <no description> = 999, n = 5
   * CIVIL PENALTY ASSESSMENT = 310, n = 2, CE_ENF_FORMAL = 1, REVISED = Civil Penalty Assessment
   * FINAL 3008(A) EQC HEAR OFF ORDER = 310, n = 2, CE_ENF_FORMAL = 1, REVISED = Final 3008(a) Environmental Quality Commission Hearing Officer Order
* 317
   * FINAL 3008(A) EQC ORDER = 310, n = 4, CE_ENF_FORMAL = 1, REVISED = Final 3008(a) Environmental Quality Commission Order
   * <no description> = 999, n = 2
* 318
   * <no description> = 999, n = 98
   * DEP FINAL ADMINISTRATIVE ORDER = 310, n = 91, CE_ENF_FORMAL = 1, REVISED = FL DEP Final Administrative Order
   * REMEDIAL ACTION ORDER = 340, n = 1, CE_ENF_FORMAL = 1, REVISED = Remedial Action Order
* 319
   * <no description> = 999, n = 6
* 325
   * <no description> = 999, n = 2
* 343
   * <no description> = 999, n = 1
* 344
   * FINAL 3008(H) SFO ORDER = 340, n = 1, CE_ENF_FORMAL = 1, REVISED = Final 3008(h) Stipulated Final Order
* 345
   * STATE EQUIVALENT 3008(H) CA ORDER = 340, n = 6, CE_ENF_FORMAL = 1, REVISED = State Equivalent 3008(h) CA Order
   * FINAL 3008(H) DEFAULT ORDER = 340, n = 1, CE_ENF_FORMAL = 1, REVISED = Final 3008(h) Default Order
* 346
   * <no description> = 999, n = 3
* 351
   * FINAL EXPEDITED ENFORCEMENT OFFER = 305, n = 30, CE_ENF_FORMAL = 1, REVISED = Final Expedited Enforcement Offer
* 366
   * <no description> = 999, n = 1
* 383
   * <no description> = 999, n = 14
* 386
   * <no description> = 999, n = 323
   * Single Site CAFO and DCC = 385, n = 32, CE_ENF_FORMAL = 1, REVISED = Single Site CA/FO and DCC
* 387
   * Satisfaction Letter = 999, n = 28, NEW = 908, REVISED = Satisfaction Letter
* 388
   * Notice of Significant Non-Compliance (for CAO with DCC) = 999, n = 1, NEW = 903, REVISED = Notice of Significant Noncompliance for Corrective Action Order With DCC
* 389
   * <no description> = 999, n = 2
* 415
   * <no description> = 999, n = 131
* 432
   * <no description> = 999, n = 2
* 435
   * <no description> = 999, n = 1
* 436
   * <no description> = 999, n = 1
* 502
   * NOTICE OF CIVIL ADMINISTRATIVE PENALTY = 210, n = 44, CE_ENF_FORMAL = 1, REVISED = Notice of Civil Administrative Penalty
* 511
   * SETTLEMENT AGREEMENT BY WV DEP LEGAL SERVICES = 610, n = 9, CE_ENF_FORMAL = 1, REVISED = Settlement Agreement by WV DEP Legal Services
* 512
   * CIVIL ADMINISTRATIVE PENALTY [FOLLOWING HEARING] = 310, n = 97, CE_ENF_FORMAL = 1, REVISED = Civil Administrative Penalty Following Hearing
   * <no description> = 999, n = 5
   * PETITION FOR CONTEMPT = 999, n = 3, CE_ENF_FORMAL = 1, REVISED = Petition for Contempt
* 513
   * APPEAL TO EQB = 999, n = 11, NEW = 910, REVISED = Appeal to Environmental Quality Board
* 514
   * <no description> = 999, n = 1
* 515
   * CIVIL ACTION FOR COMPLIANCE = 510, n = 140, CE_ENF_FORMAL = 1, REVISED = Civil Action for Compliance
   * CIVIL JUDICIAL COMPLAINT = 510, n = 49, CE_ENF_FORMAL = 1, REVISED = Civil Judicial Complaint
* 517
   * SUMMARY CITATION = 250, n = 1, CE_ENF_FORMAL = 1, REVISED = Summary Citation
* 525
   * CIVIL ACTION FOR IMMINENT HAZARDS = 520, n = 5, CE_ENF_FORMAL = 1, REVISED = Civil Action for Imminent Hazards
* 595
   * COMBINED CIVIL ACTION = 510, n = 15, CE_ENF_FORMAL = 1, REVISED = Combined Civil Action
* 611
   * COMMONWEALTH COURT ORDER = 610, n = 2, CE_ENF_FORMAL = 1, REVISED = Commonwealth Court Order
   * <no description> = 999, n = 1
* 615
   * JUDICIAL CONSENT DECREE = 610, n = 157, CE_ENF_FORMAL = 1, REVISED = Judicial Consent Decree
   * PARTIAL JUDICIAL ORDER = 610, n = 3, CE_ENF_FORMAL = 1, REVISED = Partial Judicial Order
* 621
   * JUDICIAL ORDER, NO PENALTIES = 610, n = 11, CE_ENF_FORMAL = 1, REVISED = Judicial Order - No Penalties
* 622
   * STIPULATED JUDICIAL ORDER, WITH PENALTY = 610, n = 153, CE_ENF_FORMAL = 1, REVISED = Stipulated Judicial Order With Penalty
* 625
   * FINAL JUDICIAL ORDER ISSUED = 610, n = 35, CE_ENF_FORMAL = 1, REVISED = Final Judicial Order Issued
   * Civil Contempt Order = 610, n = 1, CE_ENF_FORMAL = 1, REVISED = Civil Contempt Order
* 725
   * <no description> = 999, n = 3
* 732
   * <no description> = 999, n = 1
* 735
   * <no description> = 999, n = 43
* 736
   * <no description> = 999, n = 2
* 738
   * <no description> = 999, n = 2
* 741
   * <no description> = 999, n = 4
* 805
   * <no description> = 999, n = 298
* 809
   * ADMINISTRATIVE REFERRAL TO DENR COLLECTION UNIT = 865, n = 18, CE_ENF_FORMAL = 1, REVISED = Administrative Referral to NC DENR Collection Unit
* 815
   * <no description> = 999, n = 1
* 831
   * STATE RCRA/REFER TO STATE SUPERF/REMEDIA = 830, n = 42, CE_ENF_FORMAL = 1, REVISED = State RCRA Referral to State Superfund or Remediation
   * <no description> = 999, n = 13
* 832
   * REFERRAL TO MULTI-MEDIA ENF. = 860, n = 1, CE_ENF_FORMAL = 1, REVISED = Referral to Multi-Media Enforcement
* 835
   * DEP RCRA REFERRAL TO DEP CLEANUP = 830, n = 23, CE_ENF_FORMAL = 1, REVISED = FL DEP RCRA Referral to FL DEP Cleanup
   * <no description> = 999, n = 12
* 841
   * <no description> = 999, n = 1
* 851
   * <no description> = 999, n = 40
* 859
   * <no description> = 999, n = 24
* 861
   * <no description> = 999, n = 4
* 862
   * <no description> = 999, n = 33
* 863
   * <no description> = 999, n = 7
* 868
   * <no description> = 999, n = 2
* 870
   * <no description> = 999, n = 26
   * RCRA ACTION DROPPED-NO VIOLATION = 999, n = 1, NEW = 908, REVISED = RCRA Action Dropped - No Violation

## Where the undefined codes land

| Defined code | Actions |
| ------------ | ------- |
| 120 | 34,089 |
| 999 | 31,669 |
| 310 |  4,929 |
| 110 |  4,672 |
| 210 |  3,963 |
| 140 |    441 |
| 610 |    386 |
| 240 |    367 |
| 250 |    272 |
| 510 |    204 |
| 305 |    141 |
| 830 |     65 |
| 385 |     32 |
| 865 |     18 |
| 340 |      9 |
| 520 |      5 |
| 220 |      1 |
| 860 |      1 |

The 999 total of 31,669 actions is dominated by pairs with no description at all.
