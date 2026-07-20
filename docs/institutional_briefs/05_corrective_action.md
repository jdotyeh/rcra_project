# Corrective Action

## What it is

Corrective action is the cleanup arm of the program. When hazardous waste or its
constituents have been released into soil, groundwater, surface water, or air at a
regulated facility, the facility is required to investigate and clean up the
release. ==The obligation usually attaches to a treatment, storage, and disposal
facility through its permit, and it can also be imposed by an order.== The work runs
as a sequence of stages that moves from an initial assessment, through
investigation of the nature and extent of contamination, to selection of a remedy,
its construction, and long-term operation until the cleanup goals are met.

Because the work unfolds over years, the record is a series of events and
milestones rather than a single entry. Each milestone marks a step reached at a
facility or at a specific area of contamination within it.

## Implications for the data

The Corrective Action master file in `code/modules/02_modular_master_files/` is
built from the central event table crossed with the module's linked dimensions,
so a facility contributes many rows as its milestones and contaminated areas
accumulate. @@A row is an event at an area, not a facility, so counting facilities
means collapsing over events and areas rather than counting rows.@@ The project
builds a master file for this module but does not yet build a corrective action
panel, so the master is the current endpoint for this module.
