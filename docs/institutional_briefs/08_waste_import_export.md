# Waste Import and Export

## What it is

Hazardous waste that crosses a national border is subject to an extra layer of
control. ==Before waste can be shipped out of or into the United States, the
governments involved must consent, and the movement is documented through a system
of notices and consents.== Trade among the wealthier industrial countries runs under
an international decision that sets common procedures, and other movements run
under bilateral arrangements. The Environmental Protection Agency processes the
notices and tracks the shipments in the Waste Import Export Tracking System, whose
initials give the module its name.

The record has two sides. An export notice is the consented plan for shipping a
waste stream out of the country, and an import notice is the consented plan for
bringing a waste stream in. Annual reports then record what actually moved against
those consents.

## Implications for the data

The project builds two master files in `code/modules/02_modular_master_files/`,
one for the export side and one for the import side, each joining the consent
record to its dimension tables and to the annual reports. The two are mirror
images of each other. @@A row is a notice or waste stream rather than a shipment or a
facility, so the consented plan and what actually moved are different things and
should not be conflated.@@ The project builds these master files but does not build
an import or export panel.
