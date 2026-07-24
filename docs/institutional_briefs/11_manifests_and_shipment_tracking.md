# Manifests and Shipment Tracking

## What it is

The cradle to grave idea behind Subtitle C needs a document that follows the
waste, and the manifest is that document. ==Every off-site shipment of hazardous
waste travels with a Uniform Hazardous Waste Manifest, EPA Form 8700-22, which
names the generator, the transporters, and the facility the waste is destined
for, and which each of them signs in turn as custody passes.== A continuation
sheet, Form 8700-22A in the same family, carries the additional transporters and
waste lines that do not fit on the face of the form. The designated receiving
facility signs the manifest on arrival and returns a signed copy, so a shipment
that never arrives shows up as a manifest that was never closed out.

The manifest is a shipment record rather than a facility record. One manifest
covers one movement of waste on one day, it carries a tracking number that is
unique to that movement, and it lists each waste on its own line with the waste
codes, the quantity, the container type, and the management method the receiving
facility intends to use. Where the delivered waste does not match the paperwork
the receiving facility records a discrepancy, and a shipment it will not accept
is rejected in whole or in part, which starts a new manifest for the waste that
moves on.

The obligation follows the size categories described in the
[generators and handlers](02_generators_and_handlers.md) brief. A large or small
quantity generator shipping waste off site uses a manifest, while a very small
quantity generator ordinarily does not, and waste that never leaves the site of
generation is not manifested at all.

## From paper to the electronic system

Manifests were a paper system for most of the program's life. Congress directed
EPA to build a national electronic system in a statute enacted in 2012, and the
e-Manifest system opened in mid-2018, since when receiving facilities submit
each manifest to EPA and pay a per-manifest user fee. @@The national manifest
data therefore begin in 2018 rather than at the start of the program, so they are
a short series next to the Biennial Report and cannot be used to look back at
earlier shipments.@@ Paper manifests remain legal and are entered into the same
system by the receiving facility, so the record covers both forms of the document
while carrying the differences in timeliness that come with them.

## Implications for the data

The e-Manifest module of RCRAInfo is the `em` module, and its tables are
downloaded by `code/modules/01_download/rcrainfo/` into `data/rcrainfo/em/`.
`EM_MANIFEST.csv` holds one row per manifest, keyed by its tracking number and
carrying the shipped and received dates along with the handler identifiers of the
generator and the designated facility. `EM_WASTE_LINE.csv` holds one row per
waste on the manifest, with the federal and state waste codes, the management
method code, and the quantity in tons. The remaining tables carry the
transporters, the rejections, the import and export sides, and the
polychlorinated biphenyl detail.

@@A row in these tables is a shipment or a waste line on a shipment, not a
facility and not a facility-year,@@ so any facility-level use of them means
aggregating over manifests and choosing which side of the shipment the facility
sits on. The generator side and the receiving side both appear, and a facility
that both generates and receives waste appears on both.

The project downloads this module but does not build a master file or a panel
from it. Its use here is as the route to disaggregate the Biennial Report
tonnage totals, because the manifest lines carry the waste code and the
management method that the facility-year totals in
`BR_PANEL_2015_2023_BALANCED.csv` collapse away. That route, along with the
warning that a shipped weight on a manifest and a counted Biennial Report ton are
not the same quantity, is set out in the panel's own decision record under the
heading on extending the tonnage totals. The code sets the waste lines use are
described in the
[waste codes and management methods](12_waste_codes_and_management_methods.md)
brief, and the identifiers that join a manifest to a facility are described in
the [facility identifiers](09_facility_identifiers.md) brief.
