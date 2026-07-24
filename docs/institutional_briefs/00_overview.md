# Institutional Overview

## What the program is

The Resource Conservation and Recovery Act of 1976 gave the federal government
authority over solid and hazardous waste. The statute divides that authority
into subtitles, and three of them carry programs. ==Subtitle C is the hazardous
waste program and the source of everything in this project.== Subtitle D governs
ordinary solid waste, sets minimum criteria for landfills, and bars open
dumping, and it is carried out almost entirely by states and localities.
Subtitle I regulates underground storage tanks holding petroleum or hazardous
substances. Subtitle C is built on a cradle to grave idea, which is that a
hazardous waste should be tracked and controlled from the moment it is
generated, through transport, to its final treatment or disposal. Almost every
record in this project is a byproduct of that tracking system.

The program regulates three kinds of actors, together called handlers. Generators
produce hazardous waste. Transporters move it. Treatment, storage, and disposal
facilities, abbreviated TSDFs, hold or process it at the end of the line. A single
site can play more than one of these roles. The obligations a site carries scale
with how much waste it generates, so the amount generated is not just a number in
a table but the thing that decides which rules apply.

## What makes a waste hazardous

A waste enters Subtitle C by one of two doors. ==A listed waste appears on one of
the EPA lists, which are the F list for wastes from common industrial processes,
the K list for wastes from specific industries, and the P and U lists for
discarded commercial chemical products, with the P list reserved for the acutely
hazardous ones.== ==A characteristic waste exhibits ignitability, corrosivity,
reactivity, or toxicity, and those wastes carry D codes.== @@The determination is
the generator's own legal responsibility, so the waste codes that fill the
Biennial Report and manifest records are self-classifications made under these
rules rather than assignments made by the agency.@@ Authorized states can regulate
wastes the federal lists do not reach, which is where the state-only waste codes
discussed in [04_state_authorization.md](04_state_authorization.md) come from. A
waste that is hazardous under this statute and also radioactive under the Atomic
Energy Act is called mixed waste and answers to both regimes at once.

## How the program runs

The Environmental Protection Agency wrote the federal rules, but it does not run
the program in most of the country. Under a provision of the statute the agency
authorizes states to operate their own hazardous waste programs in place of the
federal one, and ==a state program may be stricter than the federal floor.== To be
authorized a state must demonstrate that its program is equivalent to the
federal one, consistent with the federal program and with the programs of other
states, and adequate in its enforcement authority and resources. ==Authorization
gives the state the lead, but the federal agency keeps an oversight role and can
act on its own when a state fails to respond to a significant violation.== @@As a
result the same underlying activity can be recorded differently from one state to
the next,@@ which is a theme that runs through several of these briefs and is
treated on its own in [04_state_authorization.md](04_state_authorization.md).

The program works through a small number of instruments. A site announces itself
and its activities by filing a notification and receiving an identification
number. Each shipment of waste travels with a manifest that follows it from
generator to destination. Larger sites periodically report the waste they handled
in the National Biennial Report. Regulators inspect sites, cite violations, and
bring enforcement actions. Facilities that treat, store, or dispose of waste need
permits, must clean up releases through corrective action, and must prove in
advance that they can pay for closure and cleanup through financial assurance.

## How oversight escalates

The compliance side of the program runs as a chain from review to violation to
designation to response, and each link has its own vocabulary. A review is
called a compliance evaluation, and the common types are the compliance
evaluation inspection, which is the standard comprehensive on-site review, the
focused compliance inspection aimed at a specific area of concern, the case
development inspection conducted in support of ongoing enforcement, the
compliance schedule evaluation that checks progress against a previously agreed
schedule of corrections, and the financial record review that examines financial
assurance mechanisms. The statute sets inspection floors only at the top of the
universe. ==Permitted TSDFs are to be inspected at least every two years, and
facilities owned or operated by governments are to be inspected every year==,
while @@generators have no fixed statutory frequency@@ and are covered under agency
monitoring strategies as resources allow.

Violations found in an evaluation are sorted by severity, from those that
present an actual or potential hazard to human health or the environment or that
deviate significantly from the requirements, down to lesser deviations and
paperwork or recordkeeping lapses. ==A facility becomes a significant noncomplier
when a serious violation goes unresolved without a timely enforcement response,
when lesser violations form a pattern, or when it commits a violation treated as
significant by definition, such as operating a TSDF without a permit, disposing
of hazardous waste in an unpermitted manner, or failing to maintain required
financial assurance.== The enforcement response then runs a ladder. Informal
actions such as a notice of violation or a warning letter answer minor or
first-time problems. Formal administrative actions bind the facility, whether as
a negotiated administrative order on consent, a unilateral administrative order
imposed without negotiation, or an administrative penalty order that assesses
money. Civil judicial enforcement, referred to the Department of Justice or a
state attorney general, carries the serious and unresolved cases and can end in
injunctive relief and large penalties. The
[compliance and enforcement brief](03_compliance_and_enforcement.md) describes
how these events appear in the data.

## When records must reach the national database

RCRAInfo is filled in by the implementing agencies, and federal guidance sets
expectations for how quickly. ==A compliance evaluation is to be entered within 60
days of its completion.== A violation is to be entered when it is identified, an
enforcement action when it is initiated and again as it progresses, and a
significant noncompliance designation promptly when it is made, with the record
updated when the facility returns to compliance. These expectations matter for
reading the data, @@because the most recent months are systematically incomplete
and because entry lags can differ across the states that do their own data
entry.@@

## How the program maps to the data

The project draws on two EPA systems. RCRAInfo is the national database of record
for the program, and its module tables are the backbone of the analysis. ECHO,
the Enforcement and Compliance History Online system, republishes compliance and
enforcement data in a flatter form that is easier to work with. The table below
maps each program function to the module that carries it and to the brief that
explains it.

| Program function | RCRAInfo module | Brief |
|---|---|---|
| Who a site is and what it does | Handler (hd) | [02](02_generators_and_handlers.md), [09](09_facility_identifiers.md), [13](13_universal_waste_used_oil_and_recycling.md) |
| Periodic waste reporting | Biennial Report (br) | [01](01_biennial_report.md), [12](12_waste_codes_and_management_methods.md) |
| Inspections, violations, enforcement | Compliance Monitoring and Enforcement (ce) | [03](03_compliance_and_enforcement.md), [14](14_regulatory_citations.md) |
| Cleanup of releases | Corrective Action (ca) | [05](05_corrective_action.md) |
| Permits, closure, post-closure | Permitting (pm) | [06](06_permitting_and_closure.md) |
| Proof of ability to pay | Financial Assurance (fa) | [07](07_financial_assurance.md) |
| Cross-border waste movement | Waste Import Export Tracking System (wt) | [08](08_waste_import_export.md) |
| Shipment tracking | e-Manifest (em) | [11](11_manifests_and_shipment_tracking.md) |

Most of these records begin life on a small set of EPA forms. The notification,
the Hazardous Waste Report, and the Part A permit application are described in
[10_epa_forms.md](10_epa_forms.md), which also explains the values EPA computes
from the filings rather than collects on them.

The panels built in `code/modules/03_panels/` sit on top of these modules. The
balanced and unbalanced panels are drawn from the Biennial Report and the Handler
module, and the evaluation, enforcement, and violation panels are drawn from the
Compliance Monitoring and Enforcement module. The facts in these briefs are the
reason those panels are built the way they are.
