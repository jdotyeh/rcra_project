# Waste Codes and Management Methods

## How a waste is named

Every hazardous waste in the program carries one or more codes, and the codes are
the vocabulary in which the records describe what the waste is. ==A waste is
hazardous either because it exhibits a measured characteristic or because it
appears on one of the federal lists, and the code says which of the two applies.==
The characteristic codes run from D001 for ignitability, D002 for corrosivity, and
D003 for reactivity, through the toxicity codes D004 and above, each of which
names a constituent that leached above its regulatory level in a laboratory test.
The listed codes come in four families, the F codes for wastes from non-specific
sources such as spent solvents, the K codes for wastes from specific industries,
the P codes for discarded commercial chemical products that are acutely
hazardous, and the U codes for the remaining listed commercial chemical products.

A waste can carry several codes at once, because a listed solvent that also
ignites is both. @@The codes are self-classifications made by the generator rather
than determinations made by a regulator,@@ which is the point made in the
[institutional overview](00_overview.md), so a code records what the generator
concluded about its own waste at the time it filed.

## State codes and the owner prefix

An authorized state may regulate wastes the federal lists do not reach, and its
own codes then appear alongside the federal ones. The records keep the two apart
by recording who owns each code. In `BR_GM_WASTE_CODE.csv` and
`BR_WR_WASTE_CODE.csv` every waste-code row carries a `WASTE CODE OWNER` beside
the code itself, `HQ` for a federal code and a state postal abbreviation for a
state code, so a state code that happens to read like a federal one stays
distinct. @@A state code appears only for the states that maintain one, so its
absence describes the state rather than the waste,@@ a point developed in the
[state authorization](04_state_authorization.md) brief.

## The other code sets

The waste code says what the waste is. Three further code sets on the Biennial
Report say where it came from, what form it takes, and what was done with it,
and each has its own lookup table shipped with the module in
`data/rcrainfo/br/`.

| Code set | Lookup table | What it records |
|---|---|---|
| Source code | `BR_LU_SOURCE_CODE.csv` | The process that produced the waste, such as `G01` for rinsing or `G09` for other production, and `G61` for waste received from off site for bulking and transfer. 52 codes, of which 39 are active. |
| Form code | `BR_LU_FORM_CODE.csv` | The physical and chemical form of the waste, such as `W001` for lab packs without acute waste or `W002` for contaminated debris. 51 codes, of which 50 are active. |
| Management method | `BR_LU_MANAGEMENT_METHOD.csv` | What was done with the waste, such as `H010` for metals recovery, `H040` for incineration, `H050` for energy recovery, `H132` for landfill, and `H141` for storage and transfer off site. 67 codes, of which 52 are active. |
| Waste minimization | `BR_LU_WASTE_MINIMIZATION.csv` | The reduction or recycling initiative the facility reports for the waste stream. 9 codes, of which 6 are active. |

The retired codes matter for a long series. A code marked inactive was in use in
earlier cycles and still appears in the older files, so @@a lookup restricted to
the active codes will silently fail to describe part of the historical record.@@

## Implications for the data

The waste codes sit one level below the unit the panels are built on. The
Biennial Report keeps them on the waste lines of its two forms, the generation
and management form and the waste received form, and the two waste-code tables
run to roughly 12 million and 40 million rows across the cycles. ==The balanced
and unbalanced panels collapse those lines into four facility-year tonnage
totals, so a panel row records how much waste a facility generated, managed,
shipped, or received in a cycle and never records what the waste was or how it
was treated.== The decision records of both panels list the dropped line fields by
name and note that they remain recoverable by joining back to the raw
`BR_REPORTING_[year].csv` files on the facility and cycle key.

A user who needs the tonnage broken out by waste and by method has two routes.
The first is that join back to the Biennial Report waste lines, which stays
inside the same reporting frame as the panel totals. The second is the manifest
data described in the
[manifests and shipment tracking](11_manifests_and_shipment_tracking.md) brief,
which pairs a waste code with a management method and a shipped quantity on each
line but covers only the years since the electronic system opened. The waste
codes also reappear in the compliance record, because a violation is written
against the part of the rules the waste falls under, which is the subject of the
[regulatory citations](14_regulatory_citations.md) brief.
