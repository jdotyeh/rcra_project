# The Three EPA Forms

## One family of paperwork

Nearly every record in this project began as an entry on one of three EPA forms,
and the three share a common core. The Site Identification Form collects who a
site is, where it sits, who owns and operates it, and which regulated activities
it performs, and that same form rides along whenever a site notifies, reports,
or applies for a permit. ==Form 8700-12 is the Site Identification Form filed on
its own as a notification. Form 8700-13 A and B is the Hazardous Waste Report,
which wraps the site form with waste-level detail every other year. Form 8700-23
is the Part A permit application, which wraps the site form with unit and
process detail for facilities that need a permit.== A fourth sibling, the Uniform
Hazardous Waste Manifest on Form 8700-22, travels with each shipment and feeds
the e-Manifest module rather than the modules described here.

## Form 8700-12, the notification

A site enters the program by filing Form 8700-12 as its initial notification of
regulated waste activity, and it receives its EPA identification number in
return. ==It files the form again as a subsequent notification whenever its
identity or activities change, so the Handler module is a stack of these filings
over time rather than a single snapshot.== Most of the indicator variables in the
Handler master file are checkboxes from this form, and the checkboxes are worth
reading as a map of the program's side doors, because each one marks a
regulatory regime with its own rules.

The core declarations are the generator category, transporter status, and
treatment, storage, or disposal activity. Around them sit the specialty regimes.
The used oil program covers oil contaminated through use and carries seven roles
on the form, the transporter, the transfer facility, the processor, the
re-refiner, the burner of off-specification used oil, and two marketer roles,
and off-specification oil is the dirtier kind that may be burned only in
EPA-authorized units. The universal waste program covers common widely generated
hazardous wastes such as batteries, pesticides, mercury-containing equipment,
and lamps, and the form flags a large quantity handler, which is one
accumulating 5,000 kg or more at a time, and a destination facility. A mixed
waste generator produces waste that is both hazardous and radioactive. A
hazardous secondary material notification covers spent materials, by-products,
and sludges that would be hazardous waste if discarded but are managed under
recycling exclusions instead.

Several regimes are keyed to specific subparts of the regulations. Subpart K
lets colleges, universities, teaching hospitals, and affiliated nonprofit
research institutes opt in to laboratory rules that move the waste determination
from the point of generation to the laboratory or central accumulation area, and
the form records the entity type and any withdrawal. Subpart P governs hazardous
waste pharmaceuticals at healthcare facilities and reverse distributors,
displaces the generator category rules for that waste once in effect, and bans
flushing pharmaceuticals down the drain. Subpart H records sites that import
hazardous waste or act as recognized traders arranging imports or exports as
principals without physically handling the waste. Subpart G flags importers and
exporters of spent lead-acid batteries, which are largely exempt when reclaimed
domestically but trigger the border rules when shipped across it. On the
facility side the form also records exemptions that spare a site full TSDF
permitting, the small quantity on-site burner exemption and the smelting,
melting, and refining furnace exemption for units that process hazardous waste
primarily to reclaim metal.

The form also handles the episodic side of generator life. ==A VSQG or SQG may
have one planned and one unplanned episodic event per year, lasting no more than
60 days, that pushes it over its monthly limit without changing its category,==
and it files Form 8700-12 to claim the episode. These filings become
`HD_EPISODIC_EVENT.csv` and its companion tables. An LQG may notify that it
consolidates waste from VSQGs under control of the same person, which becomes
`HD_LQG_CONSOLIDATION.csv`, and an LQG closing a central accumulation area or
the site itself notifies on the same form, which becomes `HD_LQG_CLOSURE.csv`.

The exemptions run the other way as well. A VSQG, one producing no more than
100 kg of hazardous waste and no more than 1 kg of acute hazardous waste in a
month, is conditionally exempt from most of the rules so long as it stays under
the limits and sends waste to an approved destination. ==It need not obtain an EPA
identification number, need not use the manifest, and need not file the Biennial
Report.== @@The smallest sites are therefore structurally invisible in these data
except where a state regulates them, where they file voluntarily, or where an
episodic or consolidation record brings them into view.@@

## Form 8700-13 A and B, the Hazardous Waste Report

The Hazardous Waste Report is the instrument behind the Biennial Report module.
LQGs and TSDFs file it for each odd-numbered data year by the first of March of
the following year, and the [Biennial Report brief](01_biennial_report.md)
covers who must file and how states vary. The package has three parts. The Site
Identification Form updates the site's identity and activities. The GM form
describes each waste stream generated on site, its waste codes, source code,
form code, quantity, and how it was managed on site or shipped off site. The WR
form describes each waste stream received from off site and who shipped it. In
`BR_REPORTING` the `BR_FORM` column records which form a row came from, `GM` for
generation and management, `WR` for waste received, and `XX` for a site that
filed only the Site Identification Form.

## The EPA-created values in the Biennial Report data

A row of `BR_REPORTING` mixes two kinds of fields, and reading them as one kind
is a mistake. @@The filer wrote the identity fields, the waste description, the
waste codes, the source, form, and management method codes, and the quantities
as reported. EPA then computes a second layer during processing,@@ and those
EPA-created values are the ones this project leans on.

The eight national-inclusion flags, `GEN_ID_INCLUDED_IN_NBR`,
`GEN_WASTE_INCLUDED_IN_NBR`, and their management, shipment, and receipt
counterparts, ==record EPA's decision about which sites and waste lines count
toward the published National Biennial Report totals,== because a filing carries
more detail than the national report is designed to sum.
==`CALCULATED_GENERATOR_STATUS` is EPA's own determination of the generator
category from the quantities reported, and it is the field whose value `L`
defines a large quantity generator in the panels.== `WASTE_CODE_GROUP` collapses
the reported waste codes to the single code that says most specifically what
makes the waste hazardous. `ACUTE_NONACUTE_STATUS` classifies the stream and is
empty when the stream is not a federal waste. `WASTE_GENERATION_ACTIVITY`,
`MANAGEMENT_CATEGORY`, and `WASTE_PROPERTY` are EPA categorizations of the
process, the management site, and the waste's properties. `FEDERAL_WASTE` flags
whether any federal code describes the stream, `WASTEWATER` is defined by fixed
sets of form and management codes, and `PRIORITY_CHEMICAL` is defined by a fixed
list of waste codes. The four tonnage columns are EPA's conversion of the
reported quantities into tons. @@In the Biennial Report summary workbooks the
dummy tab is composed entirely of these EPA-created flags,@@ which is worth
knowing when reading it, because those columns describe EPA's processing of the
filing rather than anything the filer checked.

## Form 8700-23, the Part A permit application

A TSDF permit is applied for in two parts, and only Part A is a form. Form
8700-23 is an administrative filing that identifies the facility, its owner and
operator, its regulated units, the waste codes it handles, its process codes,
and its design capacity. ==A facility that existed and was operating before the
requirements applied to it, and that filed a timely Part A, obtained interim
status, which is not technically a permit but a legally authorized operating
status that lasts while the full application is decided.== Part B is the full
technical submittal and has no form. It describes each unit's design and
operation, the groundwater monitoring program, the closure and post-closure
plans with their cost estimates, the financial assurance mechanism, the
emergency contingency plan, the corrective action program for solid waste
management units, air emission controls, and land disposal restriction
certifications. ==A final permit runs a fixed term of at most ten years.== The
permit requirement also has a trap for generators, @@because an LQG that
accumulates waste on site beyond its 90-day allowance becomes a storage facility
needing a permit, while an SQG has 180 days, or 270 when it must ship the waste
more than 200 miles.@@

## Implications for the data

The forms map cleanly onto the modules. Form 8700-12 produces the Handler
module, Form 8700-13 A and B produces the Biennial Report module, and Form
8700-23 produces the Permitting module, with the Part B commitments surfacing
later as financial assurance and corrective action records. Because every form
carries the Site Identification core, identity fields recur across modules, and
the Handler module is the authoritative place to read them.

The distinction between what the filer wrote and what EPA computed is the one to
keep in mind. Filer fields are declarations and vary in care and consistency
across sites and states. EPA-created values are applied uniformly during
processing, which is why the panels classify generators by
`CALCULATED_GENERATOR_STATUS` and sum tonnage only over lines the inclusion
flags admit, so that panel totals reconcile with the published national figures.
The declared-activity checkboxes from Form 8700-12 are the source of the
indicator variables in the Handler master file, @@so an indicator equal to `N` can
mean the box was not checked on the most recent filing rather than that the
activity never happened,@@ and the master file's recode rules treat the early
years accordingly.
