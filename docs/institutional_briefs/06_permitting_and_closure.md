# Permitting, Closure, and Post-Closure

## What it is

A facility that treats, stores, or disposes of hazardous waste generally needs a
permit to operate. The permit sets the conditions under which the facility runs
and lays out what must happen when it stops. Facilities that were already
operating when the rules took effect could continue under an interim status while
their permits were decided. ==A permit application is filed in two parts, a short
Part A that identifies the facility and its processes on Form 8700-23 and a
detailed Part B that describes operations and safeguards.==

Closure is the process of taking a unit out of service safely, by removing waste
and decontaminating or by containing what remains in place. ==A disposal unit that
keeps waste in place then enters post-closure, a long period of monitoring and
maintenance that runs for decades.== The permitting record therefore tracks not just
the granting of a permit but the events of a facility's regulated life from
application through closure and post-closure, nested under the permit series that
governs them.

## Implications for the data

The Permitting master file in `code/modules/02_modular_master_files/` is built
from the central event table crossed with the module's dimensions, including
unit-level detail. As with corrective action, a facility contributes many rows
because a permit series contains many events over time, so @@a row is a permit or
closure event rather than a facility.@@ The project builds this master file but does
not build a permitting panel.
