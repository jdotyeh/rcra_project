# Institutional Overview

## What the program is

The Resource Conservation and Recovery Act of 1976 gave the federal government
authority over solid and hazardous waste. Its Subtitle C is the hazardous waste
program, and it is built on a cradle to grave idea, which is that a hazardous
waste should be tracked and controlled from the moment it is generated, through
transport, to its final treatment or disposal. Almost every record in this
project is a byproduct of that tracking system.

The program regulates three kinds of actors, together called handlers. Generators
produce hazardous waste. Transporters move it. Treatment, storage, and disposal
facilities, abbreviated TSDFs, hold or process it at the end of the line. A single
site can play more than one of these roles. The obligations a site carries scale
with how much waste it generates, so the amount generated is not just a number in
a table but the thing that decides which rules apply.

## How the program runs

The Environmental Protection Agency wrote the federal rules, but it does not run
the program in most of the country. Under a provision of the statute the agency
authorizes states to operate their own hazardous waste programs in place of the
federal one, and a state program may be stricter than the federal floor. As a
result the same underlying activity can be recorded differently from one state to
the next, which is a theme that runs through several of these briefs and is
treated on its own in [04_state_authorization.md](04_state_authorization.md).

The program works through a small number of instruments. A site announces itself
and its activities by filing a notification and receiving an identification
number. Each shipment of waste travels with a manifest that follows it from
generator to destination. Larger sites periodically report the waste they handled
in the National Biennial Report. Regulators inspect sites, cite violations, and
bring enforcement actions. Facilities that treat, store, or dispose of waste need
permits, must clean up releases through corrective action, and must prove in
advance that they can pay for closure and cleanup through financial assurance.

## How the program maps to the data

The project draws on two EPA systems. RCRAInfo is the national database of record
for the program, and its module tables are the backbone of the analysis. ECHO,
the Enforcement and Compliance History Online system, republishes compliance and
enforcement data in a flatter form that is easier to work with. The table below
maps each program function to the module that carries it and to the brief that
explains it.

| Program function | RCRAInfo module | Brief |
|---|---|---|
| Who a site is and what it does | Handler (hd) | [02](02_generators_and_handlers.md), [09](09_facility_identifiers.md) |
| Periodic waste reporting | Biennial Report (br) | [01](01_biennial_report.md) |
| Inspections, violations, enforcement | Compliance Monitoring and Enforcement (ce) | [03](03_compliance_and_enforcement.md) |
| Cleanup of releases | Corrective Action (ca) | [05](05_corrective_action.md) |
| Permits, closure, post-closure | Permitting (pm) | [06](06_permitting_and_closure.md) |
| Proof of ability to pay | Financial Assurance (fa) | [07](07_financial_assurance.md) |
| Cross-border waste movement | Waste Import Export Tracking System (wt) | [08](08_waste_import_export.md) |
| Shipment tracking | e-Manifest (em) | [01](01_biennial_report.md), [09](09_facility_identifiers.md) |

The panels built in `code/modules/03_panels/` sit on top of these modules. The
balanced and unbalanced panels are drawn from the Biennial Report and the Handler
module, and the evaluation and enforcement panels are drawn from the Compliance
Monitoring and Enforcement module. The facts in these briefs are the reason those
panels are built the way they are.
