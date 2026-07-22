# 02_modular_master_files

Note: This folder has been verified (Jul 19).

This stage turns each RCRAInfo module into a single analysis ready master file.
Each script takes the module's central table and joins it to the module's
dimension tables, so that one wide file carries the whole module. On top of the
join, the stage recodes binary indicators to 1/0 and turns undistinguishable
negatives into an explicit unknown code, both described in the Recodes section
below.

## Scripts

The shared machinery lives in `00_function.R`: the character-preserving reader,
the two unknown-recode helpers, and the indicator conversion. Each master script
sources it, so running `00_function.R` on its own only defines functions.

There is one script per module. Each script reads its module folder under
`data/rcrainfo/`, joins the central table to its dimensions with left joins so
that a record with no match in a dimension still keeps a row, and reads every
column as text so that identifiers and date stamps survive exactly as reported.
The only columns whose text is altered afterward are the recoded indicators.

| Script | Module | Central table | Writes |
|--------|--------|---------------|--------|
| `01_hd_master.R` | Handler | HD_HANDLER | `HD_MASTER.csv` |
| `02_ce_master.R` | Compliance Monitoring and Enforcement | CE_REPORTING | `CE_MASTER.csv` |
| `03_ca_master.R` | Corrective Action | CA_EVENT | `CA_MASTER.csv` |
| `04_pm_master.R` | Permitting | PM_EVENT | `PM_MASTER.csv` |
| `05_fa_master.R` | Financial Assurance | FA_COST_ESTIMATE | `FA_MASTER.csv` |
| `06_wt_exports_master.R` | WIETS Exports | WT_NOTICES_EXPORTS | `WT_EXPORTS_MASTER.csv` |
| `07_wt_imports_master.R` | WIETS Imports | WT_NOTICES_IMPORTS | `WT_IMPORTS_MASTER.csv` |

## Unit of Analysis

A master row is the module's central record crossed with the module's
dimensions, so the unit of analysis differs by master. A central record with
several matches in a dimension legitimately expands into several rows, and a
record with no match keeps one row with that dimension blank.

| Master | One row is |
|--------|------------|
| `HD_MASTER.csv` | A handler source record crossed with its owner, operator, NAICS code, HSM activity, LQG consolidation, episodic waste, and other-ID entries. |
| `CE_MASTER.csv` | An evaluation crossed with its 3007 request, violation, enforcement action, SEP, and citation entries. |
| `CA_MASTER.csv` | A corrective-action event crossed with its linked area, the area's process unit, the linked authority, and the authority's statutory citation. |
| `PM_MASTER.csv` | A permit event crossed with its linked unit detail, the unit detail's waste code, and its subsequent-modification link. |
| `FA_MASTER.csv` | A cost estimate crossed with the mechanism details that fund it. |
| `WT_EXPORTS_MASTER.csv` | An export-notice waste stream crossed with its annual-report year. |
| `WT_IMPORTS_MASTER.csv` | An import-notice waste stream. |

## Recodes

Two recodings sit between the raw tables and the master files. Everything else
is carried verbatim.

**Unknown recodes.** The ECHO RCRAInfo download summary warns that several
Handler activity flags did not exist on the notification form for part of the
records' history, and that on such records an "N" means No or Unknown rather
than No. The Handler master makes that explicit: the affected "N" entries are
recoded to "U", and a blank Biennial Report exemption flag on a pre-2021 cycle
becomes "U" as well. The rules, applied in `01_hd_master.R` with counts from
the 2026-07-05 export:

| Rule | Records affected | Fields |
|------|------------------|--------|
| 1 | Source types I, R, E, T received before 4/1/2010 | `SHORT_TERM_GENERATOR`, `IMPORTER_ACTIVITY`, `MIXED_WASTE_GENERATOR`, `TRANSPORTER`, `TSD_ACTIVITY`, `RECYCLER_ACTIVITY`, `ONSITE_BURNER_EXEMPTION`, `FURNACE_EXEMPTION`, `UNDERGROUND_INJECTION_ACTIVITY`, `UNIVERSAL_WASTE_DEST_FACILITY`, and the seven `USED_OIL_*` flags (~717k-762k entries each) |
| 2 | Any record received before 4/1/2010 | `TRANSFER_FACILITY` (1,965,791 entries) |
| 3 | Report cycle before 2021 | `BR_EXEMPT`: blank recoded to "U" (394,241 entries; records carrying no cycle stay blank) |
| 4 | Received before 12/20/2016 | `RECOGNIZED_TRADER_IMPORTER`, `RECOGNIZED_TRADER_EXPORTER`, `SLAB_IMPORTER`, `SLAB_EXPORTER` (~2.59M entries each) |
| 5 | Received before 6/1/2017 | `RECYCLER_ACTIVITY_NONSTORAGE`, `MANIFEST_BROKER` (~31k entries each) |
| 6 | Received before 8/21/2019 | `SUBPART_P_HEALTHCARE`, `SUBPART_P_REVERSE_DISTRIBUTOR` (~2.96M entries each) |

**Indicator conversion.** Binary indicators arrive coded Y/N and leave coded
1/0, the usual convention of an economic research dataset. A column whose
values are only 1/0 is written as an integer column. A column that also
carries "U", whether shipped that way (`INCLUDE_IN_NATIONAL_REPORT`,
`FOUND_VIOLATION`, `SAME_FACILITY`) or created by the unknown recodes above,
stays text with the three codes "1"/"0"/"U", since unknowns must not read as
numbers. Two look-alikes are deliberately left alone: `ACKNOWLEDGE_FLAG` in
the Handler master, whose raw values are dozens of codes rather than Y/N, and
`AUTHORITY_REPOSITORY` in the Corrective Action master, which despite its
name carries the codes 1/2/3/X.

## FRS Coordinates

The Handler master overwrites the latitude and longitude a facility reported
with the ones the EPA Facility Registry Service publishes for the same place,
on the records where the two sources agree that they describe one facility.
`apply_frs_coordinates()` in `00_function.R` runs the override, reading
`data/frs/FRS_FACILITIES.csv` for the FRS pair and `data/frs/FRS_PROGRAM_LINKS.csv`
for the Handler-ID-to-`REGISTRY_ID` link. A handler that resolves to more than
one registry identifier, or a registry identifier that arrives on more than one
facility row with different coordinates, names more than one place and is left
with the coordinates it reported, because there is no single pair to import.

A record takes the FRS pair under either of two rules. The **address rule**
matches the record's normalised street and state against the FRS facility's,
together with either the city or the ZIP code, and is evidence about the record
itself. The **coordinate-anchor rule** applies when the handler carries at most
five distinct reported pairs, one of them the FRS pair at four decimal places,
with every other pair within a kilometre of it, so the FRS pair is the settled
centre of a tight cluster. A record that meets neither rule keeps what it
reported. The coordinates FRS publishes are carried across as the strings the
file holds, so the override introduces no rounding.

The source of each record's final pair is written to `LOCATION_COORD_SOURCE`.

| Value | Meaning |
|-------|---------|
| `HD` | The record keeps the coordinates the facility reported. |
| `FRS_ADDRESS` | The FRS pair was imported because the record's address matched the FRS facility's. |
| `FRS_COORDINATE` | The FRS pair was imported because it anchored the handler's cluster of reported pairs. |

## Structure Charts

One chart per master file, mapping the fields a master carries and how they nest.
The WIETS chart covers both the exports and the imports master, which are mirror
images. Bracketed names such as `[HD_OWNER_OPERATOR]` mark the source table when
a block does not come from the module's central table.

### hd

```
BASIC INFORMATION
├─ Big Four
│  ├─ Handler ID
│  ├─ Activity location (state)
│  ├─ Source type                 (A,B,D,E,I,K,N,R,T)
│  ├─ Sequence number
│  └─ Current record              (1/0 — most recent source record)
├─ Linkage sequence numbers
│  ├─ Owner/Operator seq
│  ├─ NAICS seq
│  ├─ HSM seq
│  ├─ Consolidation seq
│  └─ Episodic waste seq
└─ EPA bookkeeping
   ├─ Handler name
   ├─ Receive date
   ├─ Acknowledgement flag
   └─ Acknowledgement sent date

GEOGRAPHICS & DEMOGRAPHICS
├─ Accessibility code             (B,C,F,L)
├─ Primary site location          (street no/name, city, county code, state, tribal ID, EPA region, ZIP, lat, long, coord source)
└─ State district                 (owner + code)

CONTACT INFORMATION
├─ Mailing address                (street no/name, city, state, ZIP, country)
├─ Contact person                 (first, MI, last, title, email)
└─ Contact address                (street no/name, city, state, ZIP, country, phone, ext, fax)

OWNER INFORMATION                 [HD_OWNER_OPERATOR]
├─ Owner name
├─ Owner type
├─ Date became current
└─ Address                        (street no/name, city, state, ZIP, country, phone, ext, fax, email)

OPERATOR INFORMATION              [HD_OWNER_OPERATOR]
├─ Operator name
├─ Operator type
├─ Date became current
└─ Address                        (…same fields)

FACILITY GENERAL INFORMATION
├─ NAICS code                     [HD_NAICS]
├─ RCRA-regulated status
│  ├─ Non-notifier                (E,O,X)
│  ├─ Biennial Report flag        (1/0/U — U = pre-2001)
│  ├─ BR cycle
│  └─ BR exemption flag           (1/0/U — blank on pre-2021 cycle -> U, rule 3)
├─ Handler universe flags
│  ├─ Generator universe
│  ├─ Transporter universe        (1/0/U, rule 1)
│  └─ TSD universe                (1/0/U, rule 1)
│
├─ GENERATOR
│  ├─ Federal status              FED WASTE GENERATOR     (1,2,3,N,P,U; all HQ)
│  ├─ State status                STATE WASTE GENERATOR   (+ owner)
│  ├─ Short-term                  SHORT TERM GENERATOR    (1/0/U, rule 1)
│  ├─ Mixed waste                 MIXED WASTE GENERATOR   (dropped 8/21/2019; 1/0/U, rule 1)
│  ├─ Importer                    IMPORTER ACTIVITY       (262.84; 1/0/U, rule 1)
│  ├─ Subpart K — academic        (each 1/0)
│  │  ├─ College/university
│  │  ├─ Teaching hospital
│  │  ├─ Non-profit research institute
│  │  └─ Withdrawal
│  ├─ Subpart P — pharmaceuticals
│  │  ├─ Healthcare facility      (1/0/U, rule 6)
│  │  ├─ Reverse distributor      (1/0/U, rule 6)
│  │  └─ Withdrawal               (1/0)
│  ├─ Subpart H — intl shipment
│  │  ├─ Recognized trader importer  (1/0/U, rule 4)
│  │  └─ Recognized trader exporter  (1/0/U, rule 4)
│  └─ Subpart G — SLAB intl shipment
│     ├─ SLAB importer            (1/0/U, rule 4)
│     └─ SLAB exporter            (1/0/U, rule 4)
│
├─ TRANSPORTER
│  ├─ Transporter                 TRANSPORTER  (universe flag above)
│  └─ Transfer facility           TRANSFER FACILITY  (263.12; 1/0/U, rule 2)
│
├─ TSDF  (treat / store / dispose / on-site mgmt)
│  ├─ Core TSD                    TSD ACTIVITY  (universe flag above)
│  ├─ Recycler w/storage          RECYCLER ACTIVITY  (261.6; 1/0/U, rule 1)
│  ├─ Recycler no-storage         RECYCLER NONSTORAGE  (exemption; 1/0/U, rule 5)
│  ├─ Burner exempt               ONSITE BURNER EXEMPTION  (266.108; 1/0/U, rule 1)
│  ├─ Furnace exempt              FURNACE EXEMPTION  (266.100; 1/0/U, rule 1)
│  ├─ Deep-well disposal          UNDERGROUND INJECTION  (Part 148; 1/0/U, rule 1)
│  ├─ Off-site receipt            OFF SITE RECEIPT  (1/0)
│  ├─ UW large-qty handler        LQHUW  (Part 273; 1/0)
│  └─ UW destination              UNIVERSAL WASTE DEST FACILITY  (273; 1/0/U, rule 1)
│
├─ eMANIFEST
│  └─ Broker                      MANIFEST BROKER  (1/0/U, rule 5)
│
└─ Cross sub-universe — Used Oil  (Part 279; each 1/0/U, rule 1)
   ├─ Used oil transporter
   ├─ Used oil transfer facility
   ├─ Used oil processor
   ├─ Used oil re-refiner
   ├─ Off-spec used oil burner
   ├─ Off-spec marketer (directs shipment)
   └─ Spec marketer (first claims meets spec)

OTHER ID                          [HD_OTHER_ID]
├─ Other ID
├─ Same facility                  (1/0/U — U shipped in the raw data)
├─ Relationship owner
└─ Relationship

MISC.
├─ Public notes — general
├─ Specific public notes
├─ Owner public notes
├─ Operator public notes
└─ Short term generator notes
```

### ce

```
BASIC INFORMATION
├─ Handler ID
├─ Eval identifier
├─ Viol seq
├─ Enf identifier
├─ Request seq
├─ Citation seq
├─ CAFO seq
└─ SEP seq

HANDLER SNAPSHOT
├─ Handler name
├─ Handler activity location
├─ Region
├─ State
└─ Land type

EVALUATION INFORMATION
├─ Eval activity location
├─ Eval type
├─ Eval type desc
├─ Focus area
├─ Focus area desc
├─ Eval start date
├─ Eval agency                    (E,S,L)
├─ Found violation                (1/0/U)
├─ Citizen complaint              (1/0)
├─ Multimedia inspection          (1/0)
├─ Sampling                       (1/0)
├─ Not Subtitle C                 (1/0)
├─ Notice of compliance date
├─ Eval responsible person
├─ Eval suborganization
└─ Eval last change

3007 REQUEST INFORMATION
├─ Date of request
├─ Date response received
├─ Request agency                 (E,S)
└─ Request activity location

VIOLATION INFORMATION
├─ Viol activity location
├─ Viol type owner
├─ Viol type
├─ Viol short desc
├─ Determined date
├─ Viol determined by agency      (E,S)
├─ Responsible agency
├─ Scheduled compliance date
├─ Actual RTC date
├─ RTC qualifier                  (O = observed)
├─ Citation owner
├─ Citation
├─ Citation type                  (FR,SR,SS,FS,PC,OC)
├─ Former citation                (deprecated)
└─ Viol last change

ENFORCEMENT INFORMATION
├─ Enf activity location
├─ Enf type
├─ Enf type desc
├─ Enf action date
├─ Enf agency                     (E,S)
├─ Docket number
├─ Attorney
├─ Enf responsible person
├─ Enf suborganization
├─ Corrective action component    (1/0)
├─ Financial assurance requirement (1/0)
├─ Appeal
│  ├─ Appeal initiated date
│  └─ Appeal resolved date
├─ Disposition
│  ├─ Disposition status
│  ├─ Disposition status desc
│  └─ Disposition status date
├─ CA/FO
│  ├─ Respondent name
│  └─ Lead agency
└─ Enf last change

PENALTY & SEP INFORMATION
├─ Proposed amount
├─ Final monetary amount
├─ Paid amount
├─ Final count
├─ Final amount                   (monetary + SEP credit)
└─ SEP
   ├─ SEP type
   ├─ SEP type desc
   ├─ Expenditure amount
   ├─ Scheduled completion date
   ├─ Actual completion date
   └─ SEP defaulted date
```

### ca

```
BASIC INFORMATION
├─ Handler ID
├─ Area seq
├─ Event seq
└─ Process unit seq

AREA INFORMATION
├─ Area name
├─ Entire facility indicator      (1/0)
├─ Regulated unit indicator       (1/0)
├─ Release indicators
│  ├─ Air release indicator       (1/0)
│  ├─ Groundwater release indicator (1/0)
│  ├─ Soil release indicator      (1/0)
│  └─ Surface water release indicator (1/0)
├─ Area acreage
├─ EPA responsible person owner
├─ EPA responsible person
├─ State responsible person owner
└─ State responsible person

EVENT INFORMATION
├─ Event activity location
├─ Event agency                   (S,E,J,P)
├─ Event owner
├─ Event code
├─ Event dates
│  ├─ Original scheduled date
│  ├─ New scheduled date
│  ├─ Actual date
│  └─ Best date
├─ Suborganization owner
├─ Suborganization
├─ Responsible person owner
├─ Responsible person
└─ Public notes

AUTHORITY INFORMATION
├─ Authority activity location
├─ Authority agency               (S,E,J,P)
├─ Authority owner
├─ Authority type
├─ Authority dates
│  ├─ Authority effective date
│  ├─ Issue date
│  └─ End date
├─ Repository established         (1,2,3,X — not a Y/N flag, left unconverted)
├─ Responsible person owner
├─ Responsible person
├─ Suborganization owner
├─ Suborganization
├─ Statutory citation owner
└─ Statutory citation
```

### pm

```
BASIC INFORMATION
├─ Handler ID
├─ Series seq
├─ Event seq
├─ Unit seq
└─ Unit detail seq

SERIES INFORMATION
├─ Series name
├─ Responsible person owner
└─ Responsible person

EVENT INFORMATION
├─ Event activity location
├─ Event agency                   (E,S,J,P)
├─ Event owner
├─ Event code
├─ Event dates
│  ├─ Actual date
│  ├─ Schedule date orig
│  ├─ Schedule date new
│  └─ Best date
├─ Suborganization owner
├─ Suborganization
├─ Responsible person owner
├─ Responsible person
└─ Modification
   ├─ Modification indicator      (Y/N — event is a modification)
   └─ Base event modified
      ├─ Base series seq
      ├─ Base event seq
      ├─ Base event activity location
      ├─ Base event agency
      ├─ Base event owner
      └─ Base event code

UNIT DETAIL INFORMATION
├─ Unit name
├─ Effective date
├─ Current unit detail            (1/0 — most recent detail record)
├─ Capacity
│  ├─ Capacity amount
│  ├─ Capacity type               (P,O,D)
│  ├─ Number of units
│  ├─ UOM owner
│  └─ UOM type
├─ Legal operating status owner
├─ Legal operating status
├─ Commercial status              (0,1,2,3)
├─ Standardized permit ind        (1/0)
├─ Process code owner
├─ Process code                   (S,T,D)
├─ Waste code owner
└─ Waste code
```

### fa

```
BASIC INFORMATION
├─ Handler ID
├─ Cost coverage seq
├─ Mech seq
└─ Mech detail seq

COST ESTIMATE INFORMATION
├─ Cost activity location
├─ Cost FA type                   (C,P,A,S,N,B)
├─ Cost agency                    (S,E)
├─ Cost estimate amount
├─ Cost estimate date
├─ Cost estimate reason
├─ Update due date
├─ Current cost estimate          (1/0)
├─ Responsible person owner
└─ Responsible person

MECHANISM INFORMATION
├─ Mech activity location
├─ Mech agency                    (S,E)
├─ Mech type owner
├─ Mech type
├─ Provider
├─ Provider contact name
├─ Provider contact phone
├─ Provider contact email
└─ Mechanism detail
   ├─ Face value amount
   ├─ Facility face value amount
   ├─ Effective date
   ├─ Expiration date
   ├─ Alternative                 (1,2)
   └─ Current mechanism detail    (1/0)
```

### wt (exports and imports)

```
BASIC INFORMATION
├─ Notice ID
├─ Direction                      (Export/Import — source file)
├─ Waste stream number
└─ Consent number

NOTICE INFORMATION
├─ Notice type
├─ Notice progress
├─ Notice status
└─ Last updated date

PARTY INFORMATION
├─ Exporter
│  ├─ Exporter name
│  ├─ Exporter EPA ID
│  ├─ Exporter foreign ID
│  ├─ Exporter country
│  ├─ Exporter address
│  └─ Exporter mail address
├─ Importer
│  ├─ Importer name
│  ├─ Importer EPA ID
│  ├─ Importer foreign ID
│  ├─ Importer country
│  └─ Importer address
├─ Shipper
│  ├─ Shipper name
│  ├─ Shipper EPA ID
│  ├─ Shipper foreign ID
│  ├─ Shipper country
│  └─ Shipper address
├─ Interim facility
│  ├─ Interim name
│  ├─ Interim EPA ID
│  ├─ Interim foreign ID
│  ├─ Interim country
│  ├─ Interim address
│  └─ Interim operations
└─ Final facility
   ├─ Final name
   ├─ Final EPA ID
   ├─ Final foreign ID
   ├─ Final country
   ├─ Final address
   └─ Final operations

CONSENT INFORMATION
├─ Determination
├─ Determination issued date
├─ Consent start date
├─ Consent end date
├─ Consent quantity
├─ Consent UOM
├─ Consent shipments
└─ Consent frequency

WASTE STREAM INFORMATION
├─ WS waste type                  (HAZ,SLABS,UNIV,PCB,MIXED)
├─ Waste description
├─ UN ID number
├─ Hazard class
├─ Basel waste codes
└─ EPA waste codes

ANNUAL REPORT INFORMATION
├─ Quantity actual
├─ Quantity UOM
└─ Shipments actual
```

## Outputs

Each script writes one file to `output/modular_master_files/`, named for its
module, for example `HD_MASTER.csv`. These master files are the main input to the
panel stage, and the Handler and Compliance master files in particular feed the
facility panels.

## Running

The master script runs the whole stage. To rebuild one master file, run its
script from the repository root, for example
`Rscript code/modules/02_modular_master_files/rcrainfo/01_hd_master.R`. Some of
these tables are large, so the stage is most comfortable with sixteen gigabytes or
more of memory.
