# Modular Master File Structure Charts

## hd
BASIC INFORMATION
├─ Big Four
│  ├─ Handler ID
│  ├─ Activity location (state)
│  ├─ Source type                 (A,B,D,E,I,K,N,R,T)
│  ├─ Sequence number
│  └─ Current record              (Y/N — most recent source record)
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
├─ Primary site location          (street no/name, city, county code, state, tribal ID, EPA region, ZIP, lat, long)
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
│  ├─ Biennial report flag        (Y,N,U — U = pre-2001)
│  ├─ BR cycle
│  └─ BR exemption flag
├─ Handler universe flags
│  ├─ Generator universe
│  ├─ Transporter universe        *
│  └─ TSD universe                *all
│
├─ GENERATOR
│  ├─ Federal status              FED WASTE GENERATOR     (1,2,3,N,P,U; all HQ)
│  ├─ State status                STATE WASTE GENERATOR   (+ owner)
│  ├─ Short-term                  SHORT TERM GENERATOR    *
│  ├─ Mixed waste                 MIXED WASTE GENERATOR   *  (dropped 8/21/2019)
│  ├─ Importer                    IMPORTER ACTIVITY       (262.84) *
│  ├─ Subpart K — academic
│  │  ├─ College/university
│  │  ├─ Teaching hospital
│  │  ├─ Non-profit research institute
│  │  └─ Withdrawal
│  ├─ Subpart P — pharmaceuticals
│  │  ├─ Healthcare facility      (pre-8/21/2019 N=No/Unk)
│  │  ├─ Reverse distributor      (pre-8/21/2019 N=No/Unk)
│  │  └─ Withdrawal
│  ├─ Subpart H — intl shipment
│  │  ├─ Recognized trader importer  (pre-12/20/2016 N=No/Unk)
│  │  └─ Recognized trader exporter  (pre-12/20/2016 N=No/Unk)
│  └─ Subpart G — SLAB intl shipment
│     ├─ SLAB importer
│     └─ SLAB exporter
│
├─ TRANSPORTER
│  ├─ Transporter                 TRANSPORTER  (universe flag above)
│  └─ Transfer facility           TRANSFER FACILITY  (263.12) *
│
├─ TSDF  (treat / store / dispose / on-site mgmt)
│  ├─ Core TSD                    TSD ACTIVITY  (universe flag above)
│  ├─ Recycler w/storage          RECYCLER ACTIVITY  (261.6) *
│  ├─ Recycler no-storage         RECYCLER NONSTORAGE  (exemption)
│  ├─ Burner exempt               ONSITE BURNER EXEMPTION  (266.108) *
│  ├─ Furnace exempt              FURNACE EXEMPTION  (266.100) *
│  ├─ Deep-well disposal          UNDERGROUND INJECTION  (Part 148) *
│  ├─ Off-site receipt            OFF SITE RECEIPT  *all
│  ├─ UW large-qty handler        LQHUW  (Part 273)
│  └─ UW destination              UNIVERSAL WASTE DEST FACILITY  (273) *
│
└─ Cross sub-universe — Used Oil  (Part 279)  *
   ├─ Used oil transporter
   ├─ Used oil transfer facility
   ├─ Used oil processor
   ├─ Used oil re-refiner
   ├─ Off-spec used oil burner
   ├─ Off-spec marketer (directs shipment)
   └─ Spec marketer (first claims meets spec)

OTHER ID                          [HD_OTHER_ID]
├─ Other ID
├─ Same facility
├─ Relationship owner
└─ Relationship

MISC.
├─ Public notes — general
├─ Specific public notes
├─ Owner public notes
├─ Operator public notes
└─ Short term generator notes

LEGEND
*      pre-4/1/2010 (sources I,R,E,T): N = No or Unknown
*all   pre-4/1/2010 (all sources):    N = No or Unknown
[...]  source table when not HD_HANDLER

## pm
Structure

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
├─ Current unit detail            (Y/N — most recent detail record)
├─ Capacity
│  ├─ Capacity amount
│  ├─ Capacity type               (P,O,D)
│  ├─ Number of units
│  ├─ UOM owner
│  └─ UOM type
├─ Legal operating status owner
├─ Legal operating status
├─ Commercial status              (0,1,2,3)
├─ Standardized permit ind        (Y/N)
├─ Process code owner
├─ Process code                   (S,T,D)
├─ Waste code owner
└─ Waste code

## ce
Structure

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
├─ Found violation                (Y,N,U)
├─ Citizen complaint              (Y/N)
├─ Multimedia inspection          (Y/N)
├─ Sampling                       (Y/N)
├─ Not Subtitle C                 (Y/N)
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
├─ Corrective action component    (Y/N)
├─ Financial assurance requirement (Y/N)
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

## ca
Structure

BASIC INFORMATION
├─ Handler ID
├─ Area seq
├─ Event seq
└─ Process unit seq

AREA INFORMATION
├─ Area name
├─ Entire facility indicator      (Y/N)
├─ Regulated unit indicator       (Y/N)
├─ Release indicators
│  ├─ Air release indicator       (Y/N)
│  ├─ Groundwater release indicator (Y/N)
│  ├─ Soil release indicator      (Y/N)
│  └─ Surface water release indicator (Y/N)
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
├─ Repository established         (Y/N)
├─ Responsible person owner
├─ Responsible person
├─ Suborganization owner
├─ Suborganization
├─ Statutory citation owner
└─ Statutory citation

## fa
Structure

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
├─ Current cost estimate          (Y/N)
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
   └─ Current mechanism detail    (Y/N)

## wiets
Structure

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
