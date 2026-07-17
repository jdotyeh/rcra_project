# Compliance Monitoring and Enforcement

## How oversight works

Regulators check whether sites follow the rules and act when they do not. The
first step is an evaluation, which is usually an inspection of a site, and
evaluations come in several types that record what kind of review took place and
who carried it out. When an evaluation finds a problem the regulator records a
violation, which is tied to the specific requirement that was broken and carries
dates for when it was found and when it was resolved.

A site that is far enough out of compliance is designated a significant
noncomplier, a status that marks the more serious cases and drives the priority
of a response. When a violation warrants a response the regulator brings an
enforcement action, and enforcement runs a ladder from informal notices, through
formal administrative orders that can carry monetary penalties, to judicial
referrals for the most serious matters. An action records the agency that issued
it, the type of action, and, for the formal cases, docket numbers, responsible
staff, penalties, and how the matter was resolved.

## Who acts

Either a state or the federal agency can conduct an evaluation and issue an
enforcement action, and in an authorized state the state ordinarily leads while
the federal agency retains an oversight role. The identity of the acting agency is
recorded, and organizational codes carry a state prefix, so a code reads as a
state paired with a suborganization such as a compliance division.

## Implications for the data

The Compliance Monitoring and Enforcement master file in
`code/modules/02_modular_master_files/` is the source for two of the panels. The
evaluation panel counts evaluations by type for each handler and month from
January 2015 through December 2023, and it carries indicators for whether a
violation was found along with attributes such as whether the review was prompted
by a citizen complaint, whether it was multimedia, whether sampling took place,
and whether it fell outside Subtitle C. The enforcement panel counts actions for
the same handlers and months and splits them by the issuing agency into state and
federal, and it distinguishes the nationally defined enforcement-type codes from
the ones left undefined, alongside the docket, responsible staff, disposition, and
related fields.

The split between state and federal action is only meaningful in light of how
authority is divided, so the [state authorization brief](04_state_authorization.md)
should be read next to any analysis of who enforces. The state-prefixed
organizational codes, such as a code that reads as Illinois paired with a
compliance division, come directly from this structure, and they are why the panel
keeps the state prefix rather than discarding it.
