# Regulatory Citations

## How the rulebook is organized

A violation record does not say that a facility broke the law in general. It
says which requirement was broken, and it says it by pointing at a numbered
place in the rules. ==The federal hazardous waste rules sit in title 40 of the
Code of Federal Regulations, where each part covers one area of the program and
each part divides into lettered subparts.== The parts that matter most for these
data are listed below.

| Part | What it covers |
|---|---|
| 260 | General provisions and definitions for the program. |
| 261 | Identification and listing of hazardous waste, which is where the waste codes come from. |
| 262 | Standards for generators, including accumulation, manifesting, and reporting. |
| 263 | Standards for transporters. |
| 264 | Standards for permitted treatment, storage, and disposal facilities. |
| 265 | Interim status standards for facilities operating while their permit is pending. |
| 266 | Standards for particular wastes and for burning waste in boilers and industrial furnaces. |
| 268 | Land disposal restrictions, which set what must be treated before land disposal. |
| 270 | The permit program. |
| 273 | Universal waste. |
| 279 | Used oil. |

A citation names a place inside one of these parts, so `262.34(a)` reads as
section 34 paragraph (a) of part 262. @@The section numbering changes when the
rules are rewritten, and the generator standards were reorganized in a rule
finalized in 2016 that moved the accumulation requirements out of 262.34 into
new sections,@@ so a citation recorded years apart can point at the same
obligation under two different numbers, and an old number in a recent record is
a sign of the record rather than of the rule.

## Who owns the citation

An authorized state enforces its own adopted rules rather than the federal text,
as the [state authorization](04_state_authorization.md) brief describes, and its
rules carry its own numbering. ==A citation is therefore recorded together with
the owner of the rule cited, so a federal citation and a state citation that read
alike stay distinct.== The records also carry a code for what kind of authority is
being cited, distinguishing a federal regulation from a state regulation, a
federal or state statute, a condition written into a facility's own permit, and
anything else.

The violation itself carries a second, coarser code that says which area of the
rules the violation falls in rather than which sentence. Those codes are shaped
like a part and a subpart, so `262.A` is the general generator standards, `262.C`
is the pre-transport requirements, `262.D` is records and reporting, `273.B` is
small quantity handlers of universal waste, and `279.C` is used oil generators.
@@A state that writes a violation against its own rule can instead record the
catch-all code `XXS`, which says only that a state rule was broken and nothing
about which requirement,@@ so the coded area is missing exactly where state
enforcement is most active.

## Implications for the data

The violation panel is the place these codes surface. It carries the month's
citations in `CE_CITATION`, each prefixed with the owner of the rule as
`OWNER-CITATION`, so a federal accumulation citation reads as `HQ-262.34(a)` and
an Ohio used oil citation as `OH-279-54(C)(1)`. `CE_CITATION_TYPE` carries the
distinct authority codes of the month, where `FR` is a federal regulation, `SR` a
state regulation, `SS` a state statute, `FS` a federal statute, `PC` a permit
condition, and `OC` another citation, and `CE_CITATION_NUM` counts the distinct
owner and citation pairs.

The coded areas appear as counts. The panel carries a count and an indicator for
each of the six most common violation type codes, namely `262.A`, `262.C`,
`262.D`, `273.B`, `279.C`, and `XXS`, and pools the remaining 105 codes into a
single other count. @@Which of those 105 fired in a month is therefore not
recoverable from the panel alone and needs a join back to `CE_MASTER.csv` on the
violation key.@@

Two limits are worth carrying into any analysis of these columns. Citations are
absent altogether on 22.14 percent of the violations in the panel window, so a
violation is often recorded without the specific rule it rests on, and the
`XXS` code makes the state share of the coded areas uninformative about
substance. Reading the citation columns as a measure of what facilities do wrong
therefore works better for federally cited violations than for state ones, which
is the same asymmetry the
[compliance and enforcement](03_compliance_and_enforcement.md) brief describes
for enforcement itself. The waste codes that decide which part of the rules a
facility falls under in the first place are described in the
[waste codes and management methods](12_waste_codes_and_management_methods.md)
brief, and the two lighter regimes behind `273.B` and `279.C` are described in
the
[universal waste, used oil, and recycling](13_universal_waste_used_oil_and_recycling.md)
brief.
